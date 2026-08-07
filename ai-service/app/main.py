"""
main.py — Lớp API HTTP (FastAPI) cho mobile app gọi vào.

LƯU Ý KIẾN TRÚC: file này CHỈ là lớp vỏ — nhận request, gọi core service,
trả response. Toàn bộ logic AI nằm trong app/core (thuần Python, không phụ
thuộc FastAPI). Nếu sau này nhóm đổi sang Flask/Django/Node thì chỉ viết lại
file này, lõi AI giữ nguyên 100%.

Chạy:  uvicorn app.main:app --reload --port 8000
Docs tự động:  http://localhost:8000/docs
"""

from __future__ import annotations

import logging
from typing import Optional

from fastapi import FastAPI
from pydantic import BaseModel, Field

from .core.answer_service import AnswerService
from .core.insight_service import InsightService
from .core.models import (EducationLevel, ExplanationStyle, Question,
                          QuizQuestion, QuizType, StudentProfile)
from .core.quiz_service import QuizService

logging.basicConfig(level=logging.INFO)

app = FastAPI(
    title="AI Study Mentor — AI Service",
    description="Module AI: trả lời câu hỏi, sinh quiz, chấm điểm, insights. "
                "BrightPath Learning — Unit 22 Application Development.",
    version="1.0.0",
)

# Khởi tạo 1 lần, dùng chung ProviderManager + Cache cho cả app
_answer_service = AnswerService()
_quiz_service = QuizService(provider_manager=_answer_service.providers)
_insight_service = InsightService(provider_manager=_answer_service.providers)


# ─────────────────────────── Request schemas ───────────────────────

class ProfileIn(BaseModel):
    user_id: str
    education_level: EducationLevel = EducationLevel.HIGH_SCHOOL
    preferred_style: ExplanationStyle = ExplanationStyle.STEP_BY_STEP
    language: str = "vi"

    def to_profile(self) -> StudentProfile:
        return StudentProfile(**self.model_dump())


class AskRequest(BaseModel):
    profile: ProfileIn
    content_text: str = ""
    image_base64: Optional[str] = Field(default=None, description="Ảnh bài tập (base64)")
    image_mime_type: str = "image/jpeg"


class QuizRequest(BaseModel):
    profile: ProfileIn
    topic: str = Field(description="Chủ đề (lấy từ lịch sử câu hỏi của học sinh)")
    num_questions: int = Field(default=5, ge=1, le=20)
    quiz_types: Optional[list[QuizType]] = None


class GradeRequest(BaseModel):
    profile: ProfileIn
    question_type: QuizType
    question_payload: dict
    user_answer: str


class InsightRequest(BaseModel):
    profile: ProfileIn
    stats: dict


# ─────────────────────────── Endpoints ──────────────────────────────

@app.get("/health")
def health():
    return {
        "status": "ok",
        "providers": [p.name for p in _answer_service.providers.providers],
    }


@app.post("/ai/answer", summary="AI Answer Generation (use case chính)")
def ask(req: AskRequest):
    question = Question(
        user_id=req.profile.user_id,
        content_text=req.content_text,
        image_base64=req.image_base64,
        image_mime_type=req.image_mime_type,
    )
    answer = _answer_service.answer_question(question, req.profile.to_profile())
    return {
        "question": {
            "question_id": question.question_id,
            "question_hash": question.question_hash,
            "subject_id": question.subject_id.value if question.subject_id else None,
            "status": question.status.value,
        },
        "answer": answer.to_dict(),
    }


@app.post("/ai/quiz/generate", summary="AI-Generated Practice Questions")
def generate_quiz(req: QuizRequest):
    questions = _quiz_service.generate_quiz(
        req.topic, req.profile.to_profile(), req.num_questions, req.quiz_types)
    return {"quiz_id": questions[0].quiz_id if questions else None,
            "questions": [q.__dict__ for q in questions]}


@app.post("/ai/quiz/grade", summary="Chấm điểm + Instant Feedback")
def grade(req: GradeRequest):
    qq = QuizQuestion(question_type=req.question_type,
                      question_payload=req.question_payload)
    graded = _quiz_service.grade_answer(qq, req.user_answer, req.profile.to_profile())
    return {"is_correct": graded.is_correct,
            "instant_feedback": graded.instant_feedback}


@app.post("/ai/insights", summary="AI-Generated Insights (Progress Tracking)")
def insights(req: InsightRequest):
    return _insight_service.generate_insights(req.stats, req.profile.to_profile())
