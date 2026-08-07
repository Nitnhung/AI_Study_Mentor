"""
models.py — Các kiểu dữ liệu lõi, KHỚP với ERD của nhóm.

Mapping với database (xem ERD):
- Question        -> bảng Questions  (content_text, image_url, extracted_text_from_image, question_hash, status)
- StudentProfile  -> bảng Users      (education_level, preferred_style)
- AIAnswer        -> bảng AI_Answers (content_data JSONB, is_cached_response, api_tokens_used, ai_model_version)
- QuizQuestion    -> bảng Quiz_Questions (question_type, question_payload JSONB, user_answer, is_correct, instant_feedback)

Chỉ dùng stdlib (dataclasses + Enum) để lõi AI không phụ thuộc framework nào
=> dễ tái sử dụng khi backend đổi từ FastAPI sang Django/Express... về sau.
"""

from __future__ import annotations

import json
import time
import uuid
from dataclasses import dataclass, field, asdict
from enum import Enum
from typing import Any, Optional


# ─────────────────────────── Enums (khớp dữ liệu app) ───────────────────────

class EducationLevel(str, Enum):
    MIDDLE_SCHOOL = "middle_school"   # THCS
    HIGH_SCHOOL = "high_school"       # THPT
    UNIVERSITY = "university"         # Đại học


class ExplanationStyle(str, Enum):
    SHORT = "short"                   # ngắn gọn
    DETAILED = "detailed"             # chi tiết
    STEP_BY_STEP = "step_by_step"     # từng bước


class Subject(str, Enum):
    """Các môn trong đề bài. Thêm môn mới = thêm 1 dòng, không sửa logic."""
    MATHEMATICS = "mathematics"
    SCIENCE = "science"
    PROGRAMMING = "programming"
    HISTORY = "history"
    LANGUAGES = "languages"
    OTHER = "other"


class Difficulty(str, Enum):
    BASIC = "basic"
    INTERMEDIATE = "intermediate"
    ADVANCED = "advanced"


class QuestionStatus(str, Enum):
    PENDING = "pending"
    ANSWERED = "answered"
    REJECTED = "rejected"   # bị chặn bởi abuse detection


class QuizType(str, Enum):
    MULTIPLE_CHOICE = "multiple_choice"
    SHORT_ANSWER = "short_answer"
    FILL_IN_BLANK = "fill_in_blank"


# ─────────────────────────────── Dataclasses ────────────────────────────────

@dataclass
class StudentProfile:
    """Hồ sơ học sinh — lấy từ bảng Users khi app gọi AI service."""
    user_id: str
    education_level: EducationLevel = EducationLevel.HIGH_SCHOOL
    preferred_style: ExplanationStyle = ExplanationStyle.STEP_BY_STEP
    language: str = "vi"  # app hướng tới HSSV Việt Nam, nhưng hỗ trợ đa ngôn ngữ


@dataclass
class Question:
    """Khớp bảng Questions trong ERD."""
    user_id: str
    content_text: str = ""
    image_url: Optional[str] = None
    image_base64: Optional[str] = None        # ảnh gửi trực tiếp từ mobile
    image_mime_type: str = "image/jpeg"
    extracted_text_from_image: Optional[str] = None
    question_id: str = field(default_factory=lambda: str(uuid.uuid4()))
    question_hash: str = ""                   # do cache module tính
    subject_id: Optional[Subject] = None      # do classifier xác định
    status: QuestionStatus = QuestionStatus.PENDING
    created_at: float = field(default_factory=time.time)

    @property
    def effective_text(self) -> str:
        """Văn bản cuối cùng dùng để hỏi AI (text + chữ trích từ ảnh)."""
        parts = [self.content_text.strip()]
        if self.extracted_text_from_image:
            parts.append(self.extracted_text_from_image.strip())
        return "\n".join(p for p in parts if p)


@dataclass
class AnswerContent:
    """
    Nội dung 'content_data' (JSONB) trong bảng AI_Answers.
    Cấu trúc CỐ ĐỊNH để mobile app render ổn định, AI chỉ đổ dữ liệu vào.
    """
    subject: str = Subject.OTHER.value
    difficulty: str = Difficulty.INTERMEDIATE.value
    direct_answer: str = ""                       # đáp án cuối, rõ ràng
    explanation: str = ""                          # lời giải chính
    steps: list = field(default_factory=list)      # các bước (nếu phù hợp)
    formulas_or_concepts: list = field(default_factory=list)
    # Answer Improvement & Learning Support (đề bài yêu cầu):
    simplified_explanation: str = ""
    alternative_approaches: list = field(default_factory=list)
    key_concepts_summary: list = field(default_factory=list)
    common_mistakes: list = field(default_factory=list)
    follow_up_questions: list = field(default_factory=list)

    def to_json(self) -> str:
        return json.dumps(asdict(self), ensure_ascii=False)

    @classmethod
    def from_dict(cls, d: dict) -> "AnswerContent":
        known = {f for f in cls.__dataclass_fields__}  # type: ignore[attr-defined]
        return cls(**{k: v for k, v in d.items() if k in known})


@dataclass
class AIAnswer:
    """Khớp bảng AI_Answers trong ERD."""
    question_id: str
    content_data: AnswerContent
    answer_id: str = field(default_factory=lambda: str(uuid.uuid4()))
    is_cached_response: bool = False
    api_tokens_used: int = 0
    ai_model_version: str = ""
    created_at: float = field(default_factory=time.time)

    def to_dict(self) -> dict:
        d = asdict(self)
        return d


@dataclass
class QuizQuestion:
    """Khớp bảng Quiz_Questions trong ERD."""
    question_type: QuizType
    question_payload: dict                 # JSONB: {question, options?, correct_answer, explanation}
    qq_id: str = field(default_factory=lambda: str(uuid.uuid4()))
    quiz_id: str = ""
    user_answer: Optional[str] = None
    is_correct: Optional[bool] = None
    instant_feedback: str = ""


@dataclass
class ProviderResult:
    """Kết quả thô từ một AI provider — chuẩn hoá để mọi provider trả về giống nhau."""
    text: str
    model_version: str
    tokens_used: int = 0
    raw: Any = None
