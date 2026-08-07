"""
providers/mock_provider.py — Provider giả lập.

Mục đích:
1. Dev/test KHÔNG tốn tiền API (đề bài nhấn mạnh "Limited AI usage budget").
2. Unit test chạy offline, CI/CD không cần API key.
3. Là "lưới an toàn" cuối cùng trong chuỗi failover: nếu mọi provider thật
   đều sập, app vẫn trả về thông báo lịch sự thay vì crash.
"""

from __future__ import annotations

import json

from ..models import ProviderResult
from .base import AIProvider


class MockProvider(AIProvider):
    name = "mock"

    def __init__(self, canned_response: str | None = None):
        self.canned_response = canned_response

    def _respond(self, user_prompt: str) -> ProviderResult:
        if self.canned_response:
            text = self.canned_response
        else:
            # Trả về JSON đúng schema để toàn bộ pipeline test được end-to-end
            text = json.dumps({
                "subject": "mathematics",
                "difficulty": "basic",
                "direct_answer": "[MOCK] Đây là câu trả lời giả lập phục vụ phát triển/kiểm thử.",
                "explanation": "Hệ thống đang chạy ở chế độ mock (chưa cấu hình API key "
                               "hoặc các AI provider tạm thời không khả dụng).",
                "steps": ["Bước giả lập 1", "Bước giả lập 2"],
                "formulas_or_concepts": [],
                "simplified_explanation": "Bản giải thích đơn giản (mock).",
                "alternative_approaches": [],
                "key_concepts_summary": ["khái niệm mock"],
                "common_mistakes": [],
                "follow_up_questions": ["Câu hỏi luyện tập (mock)?"]
            }, ensure_ascii=False)
        return ProviderResult(text=text, model_version="mock-1.0", tokens_used=0)

    def generate(self, system_prompt, user_prompt, max_output_tokens=1500, temperature=0.4):
        return self._respond(user_prompt)

    def generate_with_image(self, system_prompt, user_prompt, image_base64,
                            image_mime_type="image/jpeg", max_output_tokens=1500, temperature=0.4):
        return self._respond(user_prompt)
