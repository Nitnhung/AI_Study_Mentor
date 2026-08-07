"""
providers/base.py — "Hợp đồng" chung cho mọi nhà cung cấp AI.

ĐÂY LÀ TRÁI TIM CỦA TÍNH LINH HOẠT:
- Mọi provider (Gemini, OpenAI, hay model nào ra mắt năm sau) chỉ cần
  kế thừa AIProvider và cài 2 hàm: generate() và generate_with_image().
- Toàn bộ phần còn lại của hệ thống KHÔNG biết và KHÔNG quan tâm
  đang dùng AI nào => thay/thêm provider không làm vỡ code cũ.
  (Nguyên lý Open/Closed + Dependency Inversion trong SOLID)
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Optional

from ..models import ProviderResult


class ProviderError(Exception):
    """Lỗi từ provider — ProviderManager bắt lỗi này để failover."""

    def __init__(self, provider: str, message: str, retryable: bool = True):
        super().__init__(f"[{provider}] {message}")
        self.provider = provider
        self.retryable = retryable


class AIProvider(ABC):
    """Interface chung. Mỗi provider tự lo chi tiết HTTP/SDK của mình."""

    name: str = "base"

    @abstractmethod
    def generate(
        self,
        system_prompt: str,
        user_prompt: str,
        max_output_tokens: int = 1500,
        temperature: float = 0.4,
    ) -> ProviderResult:
        """Sinh văn bản từ prompt. Phải raise ProviderError khi thất bại."""

    @abstractmethod
    def generate_with_image(
        self,
        system_prompt: str,
        user_prompt: str,
        image_base64: str,
        image_mime_type: str = "image/jpeg",
        max_output_tokens: int = 1500,
        temperature: float = 0.4,
    ) -> ProviderResult:
        """Sinh văn bản từ prompt + ảnh (đọc đề từ ảnh bài tập)."""

    def is_configured(self) -> bool:
        """Provider đã có API key chưa? Manager dùng để bỏ qua provider chưa cấu hình."""
        return True
