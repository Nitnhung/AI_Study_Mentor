"""
providers/claude_provider.py — Anthropic Claude.

Claude API format khác Gemini/OpenAI:
- Header: x-api-key + anthropic-version (không dùng Bearer token)
- System prompt nằm ở trường "system" riêng (không phải message)
- Vision: type="image" với source.type="base64" (không phải image_url)
- Response: content[].text (không phải choices[].message.content)

Model mặc định: claude-sonnet-4-6 (cân bằng chất lượng/giá/tốc độ).
Đổi model: sửa biến CLAUDE_MODEL trong .env.
"""

from __future__ import annotations

import json
import ssl
import urllib.error
import urllib.request

from ...config import settings
from ..models import ProviderResult
from .base import AIProvider, ProviderError

_API_URL = "https://api.anthropic.com/v1/messages"
_API_VERSION = "2023-06-01"


def _make_ssl_context() -> ssl.SSLContext:
    try:
        return ssl.create_default_context()
    except Exception:
        ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE
        return ctx


_SSL_CTX = _make_ssl_context()


class ClaudeProvider(AIProvider):
    name = "claude"

    def __init__(self, api_key: str | None = None, model: str | None = None):
        self.api_key = api_key or settings.claude_api_key
        self.model = model or settings.claude_model

    def is_configured(self) -> bool:
        return bool(self.api_key)

    def _call(self, system: str, messages: list,
              max_output_tokens: int, temperature: float) -> ProviderResult:
        payload = {
            "model": self.model,
            "max_tokens": max_output_tokens,
            "temperature": temperature,
            "system": system,
            "messages": messages,
        }
        req = urllib.request.Request(
            _API_URL,
            data=json.dumps(payload).encode("utf-8"),
            headers={
                "Content-Type": "application/json",
                "x-api-key": self.api_key,
                "anthropic-version": _API_VERSION,
            },
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=settings.request_timeout_seconds,
                                        context=_SSL_CTX) as resp:
                data = json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as e:
            raw = e.read().decode("utf-8", errors="replace")[:500]
            retryable = e.code in (408, 429, 500, 502, 503, 529)
            raise ProviderError(self.name, f"HTTP {e.code}: {raw}", retryable=retryable)
        except (urllib.error.URLError, TimeoutError, OSError) as e:
            raise ProviderError(self.name, f"Network error: {e}", retryable=True)

        # ── Parse response ──────────────────────────────────────────
        if data.get("type") == "error":
            err_msg = data.get("error", {}).get("message", str(data)[:300])
            raise ProviderError(self.name, f"API error: {err_msg}", retryable=False)

        stop_reason = data.get("stop_reason", "")
        content_blocks = data.get("content", [])
        if not content_blocks:
            raise ProviderError(
                self.name,
                f"Claude trả response rỗng. stop_reason={stop_reason}",
                retryable=False,
            )

        # Ghép tất cả text blocks (thường chỉ có 1)
        text_parts = [b["text"] for b in content_blocks if b.get("type") == "text"]
        text = "\n".join(text_parts)
        if not text:
            raise ProviderError(
                self.name,
                f"Claude không trả text nào. Content types: "
                f"{[b.get('type') for b in content_blocks]}",
                retryable=False,
            )

        usage = data.get("usage", {})
        tokens = int(usage.get("input_tokens", 0)) + int(usage.get("output_tokens", 0))
        return ProviderResult(text=text, model_version=self.model, tokens_used=tokens, raw=data)

    # ── API công khai ───────────────────────────────────────────────
    def generate(self, system_prompt, user_prompt, max_output_tokens=1500,
                 temperature=0.4) -> ProviderResult:
        messages = [{"role": "user", "content": user_prompt}]
        return self._call(system_prompt, messages, max_output_tokens, temperature)

    def generate_with_image(self, system_prompt, user_prompt, image_base64,
                            image_mime_type="image/jpeg", max_output_tokens=1500,
                            temperature=0.4) -> ProviderResult:
        # Claude vision format: source.type="base64"
        messages = [{
            "role": "user",
            "content": [
                {
                    "type": "image",
                    "source": {
                        "type": "base64",
                        "media_type": image_mime_type,
                        "data": image_base64,
                    },
                },
                {"type": "text", "text": user_prompt},
            ],
        }]
        return self._call(system_prompt, messages, max_output_tokens, temperature)
