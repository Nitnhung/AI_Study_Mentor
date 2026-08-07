"""
provider_manager.py — Bộ điều phối provider: retry + failover tự động.

Đáp ứng yêu cầu phi chức năng "chạy hiệu quả và lâu dài":
- Provider lỗi tạm thời (429/5xx/mất mạng) -> tự retry với backoff.
- Provider chết hẳn -> tự chuyển sang provider kế tiếp trong danh sách ưu tiên.
- Thứ tự ưu tiên đọc từ cấu hình AI_PROVIDER_PRIORITY, không hard-code.
"""

from __future__ import annotations

import logging
import time
from typing import Callable, Optional

from ..config import settings
from .models import ProviderResult
from .providers.base import AIProvider, ProviderError
from .providers.claude_provider import ClaudeProvider
from .providers.gemini_provider import GeminiProvider
from .providers.mock_provider import MockProvider
from .providers.openai_provider import OpenAIProvider

logger = logging.getLogger("ai_service.provider_manager")

# Đăng ký provider — thêm AI mới = thêm 1 dòng ở đây + 1 file trong providers/
_REGISTRY: dict[str, Callable[[], AIProvider]] = {
    "gemini": GeminiProvider,
    "claude": ClaudeProvider,
    "openai": OpenAIProvider,
    "mock": MockProvider,
}


class AllProvidersFailedError(Exception):
    pass


class ProviderManager:
    def __init__(self, providers: Optional[list[AIProvider]] = None):
        if providers is not None:
            self.providers = providers
        else:
            self.providers = []
            for name in settings.provider_priority:
                factory = _REGISTRY.get(name)
                if factory is None:
                    logger.warning("Provider '%s' không tồn tại trong registry, bỏ qua.", name)
                    continue
                p = factory()
                if p.is_configured():
                    self.providers.append(p)
                else:
                    logger.info("Provider '%s' chưa có API key, bỏ qua.", name)
        if not self.providers:
            # Không bao giờ để danh sách rỗng — mock là lưới an toàn cuối
            self.providers = [MockProvider()]

    def _with_retry(self, fn: Callable[[], ProviderResult], provider_name: str) -> ProviderResult:
        last_err: Exception | None = None
        for attempt in range(settings.max_retries + 1):
            try:
                return fn()
            except ProviderError as e:
                last_err = e
                if not e.retryable:
                    raise
                wait = settings.retry_backoff_seconds * (2 ** attempt)
                logger.warning("Provider %s lỗi (lần %d): %s — chờ %.1fs rồi thử lại",
                               provider_name, attempt + 1, e, wait)
                time.sleep(wait)
        raise last_err  # type: ignore[misc]

    def generate(self, system_prompt: str, user_prompt: str, **kwargs) -> ProviderResult:
        return self._dispatch("generate", system_prompt, user_prompt, **kwargs)

    def generate_with_image(self, system_prompt: str, user_prompt: str,
                            image_base64: str, **kwargs) -> ProviderResult:
        return self._dispatch("generate_with_image", system_prompt, user_prompt,
                              image_base64, **kwargs)

    def _dispatch(self, method: str, *args, **kwargs) -> ProviderResult:
        errors = []
        for provider in self.providers:
            try:
                fn = getattr(provider, method)
                # FIX: dùng default arg (fn=fn) để tránh closure bug trong vòng lặp
                return self._with_retry(lambda _fn=fn: _fn(*args, **kwargs), provider.name)
            except ProviderError as e:
                logger.error("Provider %s thất bại hoàn toàn: %s — failover.", provider.name, e)
                errors.append(str(e))
        raise AllProvidersFailedError("Tất cả AI provider đều thất bại: " + " | ".join(errors))
