"""
moderation.py — Kiểm duyệt đầu vào (yêu cầu "Abuse detection to prevent spam
or inappropriate content" trong đề bài).

Chiến lược 2 lớp:
1. Lớp rẻ (chạy trước, 0 chi phí): regex/heuristic chặn spam, prompt injection,
   nội dung quá dài, ký tự rác.
2. Lớp AI (đã nhúng trong system prompt): AI từ chối câu hỏi ngoài phạm vi học tập.

Danh sách pattern để ở đây, tách khỏi logic — dễ cập nhật về sau.
"""

from __future__ import annotations

import re
from dataclasses import dataclass

from ..config import settings


@dataclass
class ModerationResult:
    allowed: bool
    reason: str = ""


# Pattern chặn prompt injection — kẻ xấu cố ghi đè vai trò của AI
_INJECTION_PATTERNS = [
    r"ignore\s+(all\s+)?(previous|prior|above)\s+instructions",
    r"you\s+are\s+now\s+(?!a\s+student)",
    r"system\s*prompt",
    r"bỏ\s*qua\s*(mọi|các)?\s*(hướng\s*dẫn|chỉ\s*thị)",
    r"jailbreak",
]

# Spam thô: lặp 1 ký tự quá nhiều, toàn link...
_SPAM_PATTERNS = [
    r"(.)\1{30,}",                      # 1 ký tự lặp > 30 lần
    r"(https?://\S+\s*){5,}",           # >= 5 link liên tiếp
]


def moderate_question(text: str) -> ModerationResult:
    if not settings.moderation_enabled:
        return ModerationResult(allowed=True)

    stripped = text.strip()
    if len(stripped) == 0:
        return ModerationResult(False, "Câu hỏi trống.")
    if len(stripped) > settings.max_question_chars:
        return ModerationResult(
            False, f"Câu hỏi quá dài (tối đa {settings.max_question_chars} ký tự). "
                   "Hãy chia nhỏ câu hỏi.")

    low = stripped.lower()
    for pat in _INJECTION_PATTERNS:
        if re.search(pat, low):
            return ModerationResult(False, "Nội dung không hợp lệ.")
    for pat in _SPAM_PATTERNS:
        if re.search(pat, low):
            return ModerationResult(False, "Nội dung giống spam.")

    return ModerationResult(allowed=True)
