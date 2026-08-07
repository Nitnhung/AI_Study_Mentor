"""
providers/openai_provider.py — OpenAI (ChatGPT) làm provider dự phòng.
FIX: thêm SSL fallback + context parameter.
"""

from __future__ import annotations

import json
import ssl
import urllib.error
import urllib.request

from ...config import settings
from ..models import ProviderResult
from .base import AIProvider, ProviderError

_API_URL = "https://api.openai.com/v1/chat/completions"


def _make_ssl_context() -> ssl.SSLContext:
    try:
        return ssl.create_default_context()
    except Exception:
        ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE
        return ctx


_SSL_CTX = _make_ssl_context()


class OpenAIProvider(AIProvider):
    name = "openai"

    def __init__(self, api_key: str | None = None, model: str | None = None):
        self.api_key = api_key or settings.openai_api_key
        self.model = model or settings.openai_model

    def is_configured(self) -> bool:
        return bool(self.api_key)

    def _call(self, messages: list, max_output_tokens: int, temperature: float) -> ProviderResult:
        payload = {
            "model": self.model,
            "messages": messages,
            "max_tokens": max_output_tokens,
            "temperature": temperature,
        }
        req = urllib.request.Request(
            _API_URL,
            data=json.dumps(payload).encode("utf-8"),
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {self.api_key}",
            },
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=settings.request_timeout_seconds,
                                        context=_SSL_CTX) as resp:
                data = json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as e:
            body = e.read().decode("utf-8", errors="replace")[:500]
            retryable = e.code in (408, 429, 500, 502, 503, 504)
            raise ProviderError(self.name, f"HTTP {e.code}: {body}", retryable=retryable)
        except (urllib.error.URLError, TimeoutError, OSError) as e:
            raise ProviderError(self.name, f"Network error: {e}", retryable=True)

        try:
            text = data["choices"][0]["message"]["content"]
        except (KeyError, IndexError, TypeError):
            raise ProviderError(self.name, f"Unexpected response: {str(data)[:300]}", retryable=False)

        tokens = int(data.get("usage", {}).get("total_tokens", 0))
        return ProviderResult(text=text, model_version=self.model, tokens_used=tokens, raw=data)

    def generate(self, system_prompt, user_prompt, max_output_tokens=1500,
                 temperature=0.4) -> ProviderResult:
        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ]
        return self._call(messages, max_output_tokens, temperature)

    def generate_with_image(self, system_prompt, user_prompt, image_base64,
                            image_mime_type="image/jpeg", max_output_tokens=1500,
                            temperature=0.4) -> ProviderResult:
        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": [
                {"type": "text", "text": user_prompt},
                {"type": "image_url",
                 "image_url": {"url": f"data:{image_mime_type};base64,{image_base64}"}},
            ]},
        ]
        return self._call(messages, max_output_tokens, temperature)
