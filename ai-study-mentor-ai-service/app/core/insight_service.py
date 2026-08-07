"""
insight_service.py — Sinh "AI-generated insights" cho Progress Tracking.

Đề bài: dashboard hiển thị nhận xét kiểu
  "You frequently ask questions about algebra equations."
  "Your accuracy in physics questions has improved this month."

Đầu vào: số liệu thống kê (backend tổng hợp từ Activity_Logs, Quizzes, Questions).
Đầu ra: danh sách nhận xét + chủ đề gợi ý ôn tập
        (phục vụ cả yêu cầu "recognize frequently asked topics and suggest review").
"""

from __future__ import annotations

import logging
from typing import Optional

from .models import StudentProfile
from .prompt_builder import build_insight_system_prompt, build_insight_user_prompt
from .provider_manager import AllProvidersFailedError, ProviderManager
from ..utils.json_extract import extract_json

logger = logging.getLogger("ai_service.insight")


class InsightService:
    def __init__(self, provider_manager: Optional[ProviderManager] = None):
        self.providers = provider_manager or ProviderManager()

    def generate_insights(self, stats: dict, profile: StudentProfile) -> dict:
        """
        stats ví dụ (backend truyền vào):
        {
          "total_questions": 142,
          "questions_by_subject": {"mathematics": 80, "science": 40, "history": 22},
          "quiz_accuracy_by_subject": {"mathematics": 0.85, "science": 0.62},
          "quiz_accuracy_last_month": {"science": 0.5},
          "frequently_asked_topics": ["phương trình bậc hai", "định luật Newton"],
          "time_spent_minutes_last_week": 320
        }
        """
        try:
            result = self.providers.generate(
                build_insight_system_prompt(profile),
                build_insight_user_prompt(stats),
                max_output_tokens=600,
                temperature=0.5,
            )
        except AllProvidersFailedError:
            return self._fallback(stats)

        parsed = extract_json(result.text)
        if isinstance(parsed, dict) and parsed.get("insights"):
            return {
                "insights": [str(i) for i in parsed.get("insights", [])][:4],
                "suggested_review_topics": [str(t) for t in parsed.get("suggested_review_topics", [])][:5],
            }
        return self._fallback(stats)

    @staticmethod
    def _fallback(stats: dict) -> dict:
        """Khi AI sập vẫn có insight cơ bản từ số liệu thô — app không bao giờ trống trơn."""
        insights = []
        by_subject = stats.get("questions_by_subject") or {}
        if by_subject:
            top = max(by_subject, key=by_subject.get)
            insights.append(f"Bạn hỏi nhiều nhất về môn {top} ({by_subject[top]} câu hỏi).")
        total = stats.get("total_questions")
        if total:
            insights.append(f"Tổng cộng bạn đã đặt {total} câu hỏi. Tiếp tục phát huy nhé!")
        return {
            "insights": insights or ["Hãy bắt đầu đặt câu hỏi để nhận phân tích học tập."],
            "suggested_review_topics": list(stats.get("frequently_asked_topics", []))[:5],
        }
