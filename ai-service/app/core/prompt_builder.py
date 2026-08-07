"""
prompt_builder.py — Xây dựng prompt cá nhân hoá.

Đáp ứng trực tiếp các yêu cầu trong đề:
- "Identifies the subject and difficulty level"
- "Uses simple language suitable for the student's level"
- "Provides step-by-step explanations when appropriate"
- "Show logical steps / Explain formulas / Provide the final answer clearly"
- Answer Improvement: simplified, alternatives, key concepts, mistakes, follow-ups

KỸ THUẬT QUAN TRỌNG: ép AI trả về JSON đúng schema AnswerContent
=> mobile app render ổn định, không phụ thuộc "văn phong" của từng model.
Đây cũng là lý do đổi provider không vỡ UI.
"""

from __future__ import annotations

from .models import (EducationLevel, ExplanationStyle, Question, QuizType,
                     StudentProfile, Subject)

# ── Mô tả trình độ (dùng trong system prompt) ──────────────────────
_LEVEL_GUIDE = {
    EducationLevel.MIDDLE_SCHOOL: (
        "Học sinh trung học cơ sở (lớp 6-9). Dùng từ ngữ đơn giản, ví dụ đời thường, "
        "tránh thuật ngữ hàn lâm; nếu buộc phải dùng thuật ngữ thì giải thích ngay."
    ),
    EducationLevel.HIGH_SCHOOL: (
        "Học sinh trung học phổ thông (lớp 10-12). Có thể dùng thuật ngữ trong chương trình phổ thông, "
        "trình bày chặt chẽ, bám sát kiến thức SGK và kỳ thi."
    ),
    EducationLevel.UNIVERSITY: (
        "Sinh viên đại học. Có thể trình bày chuyên sâu, dùng thuật ngữ chuyên ngành, "
        "ký hiệu toán học chuẩn và trích dẫn định lý/khái niệm chính xác."
    ),
}

_STYLE_GUIDE = {
    ExplanationStyle.SHORT: "Trả lời NGẮN GỌN, đi thẳng vào trọng tâm, ít chữ nhất có thể mà vẫn đúng.",
    ExplanationStyle.DETAILED: "Trả lời CHI TIẾT, giải thích đầy đủ bản chất, bối cảnh và lý do.",
    ExplanationStyle.STEP_BY_STEP: "Trả lời TỪNG BƯỚC, đánh số rõ ràng, mỗi bước nêu rõ làm gì và vì sao.",
}

# Schema JSON mà AI bắt buộc trả về — khớp 1:1 với AnswerContent (content_data JSONB)
_ANSWER_JSON_SCHEMA = """{
  "subject": "mathematics|science|programming|history|languages|other",
  "difficulty": "basic|intermediate|advanced",
  "direct_answer": "Đáp án cuối cùng, rõ ràng, ngắn gọn",
  "explanation": "Lời giải/giải thích chính theo đúng phong cách yêu cầu",
  "steps": ["Bước 1 ...", "Bước 2 ..."],
  "formulas_or_concepts": ["Công thức/khái niệm đã dùng + giải thích ngắn"],
  "simplified_explanation": "Cách giải thích đơn giản hơn nữa (như nói với người mới học)",
  "alternative_approaches": ["Cách giải/cách tiếp cận khác (nếu có)"],
  "key_concepts_summary": ["Tóm tắt khái niệm cốt lõi cần nhớ"],
  "common_mistakes": ["Lỗi sai học sinh thường mắc với dạng bài này"],
  "follow_up_questions": ["2-3 câu hỏi luyện tập tương tự để tự kiểm tra"]
}"""


def build_answer_system_prompt(profile: StudentProfile) -> str:
    lang = "tiếng Việt" if profile.language == "vi" else profile.language
    return f"""Bạn là "AI Study Mentor" — gia sư AI tận tâm, chính xác, chỉ phục vụ mục đích HỌC TẬP.

ĐỐI TƯỢNG: {_LEVEL_GUIDE[profile.education_level]}
PHONG CÁCH: {_STYLE_GUIDE[profile.preferred_style]}
NGÔN NGỮ TRẢ LỜI: {lang}.

QUY TẮC BẮT BUỘC:
1. CHÍNH XÁC là ưu tiên số 1. Nếu không chắc chắn, nói rõ phần nào chưa chắc — TUYỆT ĐỐI không bịa đáp án, không bịa công thức, không bịa sự kiện lịch sử.
2. Với bài toán/bài tập cần giải: trình bày các bước logic, giải thích công thức/khái niệm đã dùng, và nêu ĐÁP ÁN CUỐI rõ ràng.
3. Tự xác định môn học (subject) và độ khó (difficulty) của câu hỏi.
4. Hướng dẫn để học sinh HIỂU, không chỉ đưa đáp án để chép.
5. Nếu câu hỏi không liên quan học tập, nội dung không phù hợp/độc hại: đặt direct_answer = "Câu hỏi này nằm ngoài phạm vi học tập của AI Study Mentor." và để trống các trường khác.
6. Nếu đề bài trong ảnh bị mờ/thiếu dữ kiện: nêu rõ phần thiếu trong explanation và giải với giả định hợp lý nhất.

ĐỊNH DẠNG ĐẦU RA (BẮT BUỘC):
Chỉ trả về MỘT đối tượng JSON hợp lệ theo đúng schema sau, không thêm lời dẫn, không markdown, không ```:
{_ANSWER_JSON_SCHEMA}"""


def build_answer_user_prompt(question: Question) -> str:
    text = question.effective_text
    if question.image_base64 and not text:
        return "Hãy đọc đề bài trong ảnh đính kèm và giải đáp theo đúng quy tắc."
    if question.image_base64:
        return f"Câu hỏi của học sinh (kèm ảnh đính kèm, hãy đọc cả ảnh):\n{text}"
    return f"Câu hỏi của học sinh:\n{text}"


# ── Practice quiz (AI-Generated Practice Questions) ────────────────
_QUIZ_JSON_SCHEMA = """{
  "questions": [
    {
      "question_type": "multiple_choice|short_answer|fill_in_blank",
      "question": "Nội dung câu hỏi (với fill_in_blank dùng ___ cho chỗ trống)",
      "options": ["A...", "B...", "C...", "D..."],
      "correct_answer": "Đáp án đúng (với multiple_choice ghi đúng nội dung lựa chọn)",
      "explanation": "Giải thích ngắn vì sao đúng"
    }
  ]
}"""


def build_quiz_system_prompt(profile: StudentProfile) -> str:
    return f"""Bạn là AI Study Mentor, tạo câu hỏi luyện tập cho học sinh.
ĐỐI TƯỢNG: {_LEVEL_GUIDE[profile.education_level]}
NGÔN NGỮ: {"tiếng Việt" if profile.language == "vi" else profile.language}.
YÊU CẦU: câu hỏi phải CHÍNH XÁC, bám sát chủ đề được cho, độ khó phù hợp trình độ,
đáp án và giải thích phải đúng. "options" chỉ bắt buộc với multiple_choice (4 lựa chọn, 1 đúng).
Chỉ trả về MỘT JSON hợp lệ theo schema, không thêm gì khác:
{_QUIZ_JSON_SCHEMA}"""


def build_quiz_user_prompt(topic: str, num_questions: int, quiz_types: list[QuizType]) -> str:
    types = ", ".join(t.value for t in quiz_types)
    return (f"Tạo {num_questions} câu hỏi luyện tập về chủ đề: \"{topic}\".\n"
            f"Các dạng câu hỏi cần dùng (trộn đều): {types}.")


# ── Chấm điểm tự luận/điền khuyết (instant feedback) ───────────────
def build_grading_system_prompt(profile: StudentProfile) -> str:
    return f"""Bạn là AI Study Mentor, chấm câu trả lời của học sinh ({_LEVEL_GUIDE[profile.education_level]}).
So sánh câu trả lời của học sinh với đáp án chuẩn. Chấp nhận cách diễn đạt khác nhau nếu ĐÚNG về bản chất.
Chỉ trả về MỘT JSON: {{"is_correct": true|false, "feedback": "Nhận xét ngắn gọn, động viên, chỉ ra chỗ sai nếu có"}}"""


def build_grading_user_prompt(question: str, correct_answer: str, user_answer: str) -> str:
    return (f"Câu hỏi: {question}\n"
            f"Đáp án chuẩn: {correct_answer}\n"
            f"Câu trả lời của học sinh: {user_answer}")


# ── Insights (Progress Tracking — "AI-generated insights") ─────────
def build_insight_system_prompt(profile: StudentProfile) -> str:
    return f"""Bạn là AI Study Mentor, phân tích dữ liệu học tập và đưa nhận xét hữu ích, động viên.
NGÔN NGỮ: {"tiếng Việt" if profile.language == "vi" else profile.language}.
Chỉ trả về MỘT JSON: {{"insights": ["nhận xét 1", "nhận xét 2", ...], "suggested_review_topics": ["chủ đề nên ôn lại"]}}
Nhận xét phải cụ thể, dựa trên số liệu được cung cấp (vd: "Bạn hỏi nhiều về phương trình đại số",
"Độ chính xác môn Lý của bạn đã cải thiện"). Tối đa 4 nhận xét."""


def build_insight_user_prompt(stats: dict) -> str:
    import json
    return "Dữ liệu học tập của học sinh (JSON):\n" + json.dumps(stats, ensure_ascii=False, indent=2)
