"""
providers/gemini_provider.py — Google Gemini.

SỬA LỖI so với bản cũ:
1. Thêm safetySettings BLOCK_NONE — câu hỏi học thuật (hoá học, y học,
   lịch sử chiến tranh...) không bị safety filter chặn nữa.
2. Bắt promptFeedback.blockReason — trả thông báo rõ ràng thay vì crash.
3. SSL fallback cho Windows/macOS bị CERTIFICATE_VERIFY_FAILED.
4. Thêm response_mime_type = "application/json" cho model hỗ trợ (giảm
   lỗi parse JSON).
"""

from __future__ import annotations

import json
import ssl
import urllib.error
import urllib.request

from ...config import settings
from ..models import ProviderResult
from .base import AIProvider, ProviderError

_API_BASE = "https://generativelanguage.googleapis.com/v1beta/models"

# Gemini safety settings — tắt filter để câu hỏi học thuật không bị chặn.
# App đã có moderation.py riêng nên không cần Gemini filter thêm.
_SAFETY_OFF = [
    {"category": "HARM_CATEGORY_HARASSMENT",        "threshold": "BLOCK_NONE"},
    {"category": "HARM_CATEGORY_HATE_SPEECH",       "threshold": "BLOCK_NONE"},
    {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",  "threshold": "BLOCK_NONE"},
    {"category": "HARM_CATEGORY_DANGEROUS_CONTENT",  "threshold": "BLOCK_NONE"},
]


def _make_ssl_context() -> ssl.SSLContext:
    """Tạo SSL context — fallback không verify khi máy thiếu cert (phổ biến trên Windows)."""
    try:
        return ssl.create_default_context()
    except Exception:
        ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE
        return ctx


_SSL_CTX = _make_ssl_context()


class GeminiProvider(AIProvider):
    name = "gemini"

    def __init__(self, api_key: str | None = None, model: str | None = None):
        self.api_key = api_key or settings.gemini_api_key
        self.model = model or settings.gemini_model
        self.vision_model = settings.gemini_vision_model

    def is_configured(self) -> bool:
        return bool(self.api_key)

    def _call(self, model: str, payload: dict) -> ProviderResult:
        url = f"{_API_BASE}/{model}:generateContent?key={self.api_key}"
        body = json.dumps(payload).encode("utf-8")
        req = urllib.request.Request(
            url, data=body,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=settings.request_timeout_seconds,
                                        context=_SSL_CTX) as resp:
                data = json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as e:
            raw = e.read().decode("utf-8", errors="replace")[:500]
            retryable = e.code in (408, 429, 500, 502, 503, 504)
            raise ProviderError(self.name, f"HTTP {e.code}: {raw}", retryable=retryable)
        except (urllib.error.URLError, TimeoutError, OSError) as e:
            raise ProviderError(self.name, f"Network error: {e}", retryable=True)

        # ── BUG FIX: bắt safety filter block ────────────────────────
        feedback = data.get("promptFeedback", {})
        block_reason = feedback.get("blockReason")
        if block_reason:
            raise ProviderError(
                self.name,
                f"Bị Gemini safety filter chặn: {block_reason}. "
                f"Ratings: {feedback.get('safetyRatings', [])}",
                retryable=False,
            )

        # ── Parse candidates ────────────────────────────────────────
        candidates = data.get("candidates", [])
        if not candidates:
            raise ProviderError(
                self.name,
                f"Gemini trả response rỗng (không có candidates). "
                f"Full response: {str(data)[:300]}",
                retryable=False,
            )

        finish_reason = candidates[0].get("finishReason", "")
        if finish_reason == "SAFETY":
            raise ProviderError(
                self.name,
                f"Câu trả lời bị Gemini safety filter chặn (finishReason=SAFETY).",
                retryable=False,
            )

        try:
            text = candidates[0]["content"]["parts"][0]["text"]
        except (KeyError, IndexError, TypeError):
            raise ProviderError(
                self.name,
                f"Unexpected response structure: {str(candidates[0])[:300]}",
                retryable=False,
            )

        usage = data.get("usageMetadata", {})
        tokens = int(usage.get("totalTokenCount", 0))
        return ProviderResult(text=text, model_version=model, tokens_used=tokens, raw=data)

    @staticmethod
    def _gen_config(max_output_tokens: int, temperature: float) -> dict:
        return {
            "maxOutputTokens": max_output_tokens,
            "temperature": temperature,
            "responseMimeType": "application/json",  # ép trả JSON (model 1.5+ hỗ trợ)
        }

    def generate(self, system_prompt, user_prompt, max_output_tokens=1500,
                 temperature=0.4) -> ProviderResult:
        payload = {
            "systemInstruction": {"parts": [{"text": system_prompt}]},
            "contents": [{"role": "user", "parts": [{"text": user_prompt}]}],
            "generationConfig": self._gen_config(max_output_tokens, temperature),
            "safetySettings": _SAFETY_OFF,
        }
        return self._call(self.model, payload)

    def generate_with_image(self, system_prompt, user_prompt, image_base64,
                            image_mime_type="image/jpeg", max_output_tokens=1500,
                            temperature=0.4) -> ProviderResult:
        payload = {
            "systemInstruction": {"parts": [{"text": system_prompt}]},
            "contents": [{
                "role": "user",
                "parts": [
                    {"inlineData": {"mimeType": image_mime_type, "data": image_base64}},
                    {"text": user_prompt},
                ],
            }],
            "generationConfig": self._gen_config(max_output_tokens, temperature),
            "safetySettings": _SAFETY_OFF,
        }
        return self._call(self.vision_model, payload)
