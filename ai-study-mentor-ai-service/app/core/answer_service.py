"""
answer_service.py — Pipeline trả lời câu hỏi (use case "AI answer generation").

Luồng xử lý 1 câu hỏi:
  ┌─ 1. Moderation (chặn spam/injection — 0 chi phí)
  ├─ 2. Cache lookup (exact hash -> similarity) — trúng thì trả ngay, 0 token
  ├─ 3. Gọi AI (text hoặc text+ảnh) qua ProviderManager (retry + failover)
  ├─ 4. Parse JSON -> AnswerContent (schema cố định cho mobile render)
  ├─ 5. Lưu cache + trả AIAnswer (khớp bảng AI_Answers: is_cached_response,
  │      api_tokens_used, ai_model_version)
  └─ 6. Mọi lỗi đều được "hạ cánh mềm" — không bao giờ ném exception thô lên app.
"""

from __future__ import annotations

import dataclasses
import logging
from typing import Optional

from ..config import settings
from .cache import AnswerCache, question_hash
from .models import (AIAnswer, AnswerContent, Difficulty, Question,
                     QuestionStatus, StudentProfile, Subject)
from .moderation import moderate_question
from .prompt_builder import build_answer_system_prompt, build_answer_user_prompt
from .provider_manager import AllProvidersFailedError, ProviderManager
from ..utils.json_extract import extract_json

logger = logging.getLogger("ai_service.answer")


class AnswerService:
    def __init__(self, provider_manager: Optional[ProviderManager] = None,
                 cache: Optional[AnswerCache] = None):
        self.providers = provider_manager or ProviderManager()
        self.cache = cache or AnswerCache()

    # ── API chính ───────────────────────────────────────────────────
    def answer_question(self, question: Question, profile: StudentProfile) -> AIAnswer:
        text = question.effective_text

        # 1. Moderation
        mod = moderate_question(text if text else "(ảnh)")
        if not mod.allowed and not question.image_base64:
            question.status = QuestionStatus.REJECTED
            return self._rejection_answer(question, mod.reason)

        question.question_hash = question_hash(text) if text else ""

        # 2. Cache (chỉ áp dụng cho câu hỏi text — ảnh mỗi lần mỗi khác)
        if text and not question.image_base64:
            hit = self.cache.lookup(text)
            if hit is not None:
                logger.info("Cache HIT (%s) cho câu hỏi %s", hit.get("cache_tier"), question.question_id)
                content = AnswerContent.from_dict(hit["answer_content"])
                question.subject_id = self._safe_subject(content.subject)
                question.status = QuestionStatus.ANSWERED
                return AIAnswer(
                    question_id=question.question_id,
                    content_data=content,
                    is_cached_response=True,     # -> cột AI_Answers.is_cached_response
                    api_tokens_used=0,           # tiết kiệm 100% chi phí lần này
                    ai_model_version=f"cache:{hit.get('cache_tier')}",
                )

        # 3. Gọi AI
        system_prompt = build_answer_system_prompt(profile)
        user_prompt = build_answer_user_prompt(question)
        try:
            if question.image_base64:
                result = self.providers.generate_with_image(
                    system_prompt, user_prompt,
                    image_base64=question.image_base64,
                    image_mime_type=question.image_mime_type,
                    max_output_tokens=settings.max_output_tokens,
                )
            else:
                result = self.providers.generate(
                    system_prompt, user_prompt,
                    max_output_tokens=settings.max_output_tokens,
                )
        except AllProvidersFailedError as e:
            logger.error("Mọi provider thất bại: %s", e)
            return self._error_answer(question,
                "Hệ thống AI đang quá tải, vui lòng thử lại sau ít phút. "
                "Câu hỏi của bạn đã được lưu trong lịch sử.")

        # 4. Parse JSON -> AnswerContent
        parsed = extract_json(result.text)
        if isinstance(parsed, dict):
            content = AnswerContent.from_dict(parsed)
            if not content.direct_answer and not content.explanation:
                content.direct_answer = result.text.strip()[:2000]
        else:
            # AI trả văn bản tự do — vẫn dùng được, không vứt đi
            logger.warning("AI không trả JSON hợp lệ, dùng raw text. Q=%s", question.question_id)
            content = AnswerContent(direct_answer="", explanation=result.text.strip())

        question.subject_id = self._safe_subject(content.subject)
        question.status = QuestionStatus.ANSWERED

        # 5. Lưu cache cho các học sinh hỏi câu tương tự sau này
        if text and not question.image_base64 and content.direct_answer:
            self.cache.store(text, dataclasses.asdict(content), subject=content.subject)

        return AIAnswer(
            question_id=question.question_id,
            content_data=content,
            is_cached_response=False,
            api_tokens_used=result.tokens_used,   # -> cột api_tokens_used (theo dõi chi phí)
            ai_model_version=result.model_version,
        )

    # ── helpers ─────────────────────────────────────────────────────
    @staticmethod
    def _safe_subject(value: str) -> Subject:
        try:
            return Subject(value)
        except ValueError:
            return Subject.OTHER

    @staticmethod
    def _rejection_answer(question: Question, reason: str) -> AIAnswer:
        return AIAnswer(
            question_id=question.question_id,
            content_data=AnswerContent(
                subject=Subject.OTHER.value,
                difficulty=Difficulty.BASIC.value,
                direct_answer=f"Không thể xử lý câu hỏi: {reason}",
            ),
            ai_model_version="moderation",
        )

    @staticmethod
    def _error_answer(question: Question, message: str) -> AIAnswer:
        return AIAnswer(
            question_id=question.question_id,
            content_data=AnswerContent(direct_answer=message),
            ai_model_version="error",
        )
