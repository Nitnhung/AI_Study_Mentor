"""
quiz_service.py — Sinh câu hỏi luyện tập + chấm điểm tức thì.

Đáp ứng use case "AI generated practice questions":
- Dạng: multiple_choice / short_answer / fill_in_blank (đúng đề bài)
- "Instant feedback is provided after each attempt"
- Khớp bảng Quiz_Questions: question_type, question_payload (JSONB),
  user_answer, is_correct, instant_feedback.

Chấm điểm thông minh để tiết kiệm chi phí:
- multiple_choice & fill_in_blank: so khớp cục bộ (0 token).
- short_answer: so khớp cục bộ trước; chỉ khi không khớp tuyệt đối mới
  nhờ AI chấm ngữ nghĩa (chấp nhận cách diễn đạt khác).
"""

from __future__ import annotations

import logging
import uuid
from typing import Optional

from .cache import normalize_text
from .models import QuizQuestion, QuizType, StudentProfile
from .prompt_builder import (build_grading_system_prompt, build_grading_user_prompt,
                             build_quiz_system_prompt, build_quiz_user_prompt)
from .provider_manager import AllProvidersFailedError, ProviderManager
from ..utils.json_extract import extract_json

logger = logging.getLogger("ai_service.quiz")

_DEFAULT_TYPES = [QuizType.MULTIPLE_CHOICE, QuizType.SHORT_ANSWER, QuizType.FILL_IN_BLANK]


class QuizService:
    def __init__(self, provider_manager: Optional[ProviderManager] = None):
        self.providers = provider_manager or ProviderManager()

    # ── Sinh quiz từ chủ đề (lấy từ lịch sử câu hỏi của học sinh) ───
    def generate_quiz(self, topic: str, profile: StudentProfile,
                      num_questions: int = 5,
                      quiz_types: Optional[list[QuizType]] = None) -> list[QuizQuestion]:
        quiz_types = quiz_types or _DEFAULT_TYPES
        quiz_id = str(uuid.uuid4())
        try:
            result = self.providers.generate(
                build_quiz_system_prompt(profile),
                build_quiz_user_prompt(topic, num_questions, quiz_types),
                max_output_tokens=2000,
                temperature=0.7,  # quiz cần đa dạng hơn answer
            )
        except AllProvidersFailedError:
            logger.error("Không sinh được quiz cho topic=%s", topic)
            return []

        parsed = extract_json(result.text)
        questions: list[QuizQuestion] = []
        if isinstance(parsed, dict):
            for item in parsed.get("questions", []):
                qtype = self._safe_type(item.get("question_type", ""))
                if not item.get("question") or not item.get("correct_answer"):
                    continue  # bỏ câu thiếu dữ liệu — không cho dữ liệu rác vào DB
                questions.append(QuizQuestion(
                    quiz_id=quiz_id,
                    question_type=qtype,
                    question_payload={
                        "question": item["question"],
                        "options": item.get("options", []) if qtype == QuizType.MULTIPLE_CHOICE else [],
                        "correct_answer": item["correct_answer"],
                        "explanation": item.get("explanation", ""),
                    },
                ))
        return questions

    # ── Chấm điểm + instant feedback ────────────────────────────────
    def grade_answer(self, quiz_question: QuizQuestion, user_answer: str,
                     profile: StudentProfile) -> QuizQuestion:
        payload = quiz_question.question_payload
        correct = str(payload.get("correct_answer", ""))
        explanation = payload.get("explanation", "")
        quiz_question.user_answer = user_answer

        # Bước 1: so khớp cục bộ (miễn phí)
        if normalize_text(user_answer) == normalize_text(correct):
            quiz_question.is_correct = True
            quiz_question.instant_feedback = f"Chính xác! {explanation}".strip()
            return quiz_question

        # Trắc nghiệm/điền khuyết: sai là sai, không cần hỏi AI
        if quiz_question.question_type in (QuizType.MULTIPLE_CHOICE, QuizType.FILL_IN_BLANK):
            quiz_question.is_correct = False
            quiz_question.instant_feedback = (
                f"Chưa đúng. Đáp án đúng là: {correct}. {explanation}".strip())
            return quiz_question

        # Bước 2: short_answer — nhờ AI chấm ngữ nghĩa
        try:
            result = self.providers.generate(
                build_grading_system_prompt(profile),
                build_grading_user_prompt(payload.get("question", ""), correct, user_answer),
                max_output_tokens=300,
                temperature=0.0,  # chấm điểm cần nhất quán tuyệt đối
            )
            parsed = extract_json(result.text)
            if isinstance(parsed, dict) and "is_correct" in parsed:
                quiz_question.is_correct = bool(parsed["is_correct"])
                quiz_question.instant_feedback = str(parsed.get("feedback", ""))
                return quiz_question
        except AllProvidersFailedError:
            pass

        # Fallback an toàn: không chấm được thì báo đáp án chuẩn
        quiz_question.is_correct = False
        quiz_question.instant_feedback = (
            f"Hệ thống tạm thời không chấm tự động được. Đáp án tham khảo: {correct}. {explanation}".strip())
        return quiz_question

    @staticmethod
    def _safe_type(value: str) -> QuizType:
        try:
            return QuizType(value)
        except ValueError:
            return QuizType.SHORT_ANSWER
