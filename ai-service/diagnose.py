"""
diagnose.py — Chẩn đoán tại sao không gọi được API.

Chạy: python3 diagnose.py
Script này kiểm tra từng bước: .env → SSL → mạng → API key → gọi thử AI.
Khi bạn/thầy gặp lỗi, chạy file này sẽ biết CHÍNH XÁC vướng ở đâu.
"""

import json
import os
import ssl
import sys
import urllib.error
import urllib.request

# ── Đảm bảo import được ────────────────────────────────────────────
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

PASS = "✅"
FAIL = "❌"
WARN = "⚠️"


def section(title):
    print(f"\n{'─' * 60}\n  {title}\n{'─' * 60}")


def check(label, ok, detail=""):
    status = PASS if ok else FAIL
    msg = f"  {status} {label}"
    if detail:
        msg += f" — {detail}"
    print(msg)
    return ok


# ═══════════════════════════════════════════════════════════════════
section("BƯỚC 1: KIỂM TRA FILE .env")
# ═══════════════════════════════════════════════════════════════════

from app.config import settings

gemini_key = settings.gemini_api_key
claude_key = settings.claude_api_key
openai_key = settings.openai_api_key

has_any_key = bool(gemini_key or claude_key or openai_key)

check("Gemini API key", bool(gemini_key),
      f"{gemini_key[:8]}...{gemini_key[-4:]}" if gemini_key else "TRỐNG — cần điền GEMINI_API_KEY trong .env")
check("Claude API key", bool(claude_key),
      f"{claude_key[:8]}...{claude_key[-4:]}" if claude_key else "TRỐNG — cần điền CLAUDE_API_KEY trong .env")
check("OpenAI API key", bool(openai_key),
      f"{openai_key[:8]}...{openai_key[-4:]}" if openai_key else "TRỐNG — cần điền OPENAI_API_KEY trong .env")

if not has_any_key:
    print(f"\n  {FAIL} KHÔNG CÓ API KEY NÀO! Hệ thống sẽ chạy bằng MockProvider (giả lập).")
    print(f"  Cách sửa: cp .env.example .env  rồi điền ít nhất 1 key.")
    print(f"  • Gemini (miễn phí): https://aistudio.google.com/apikey")
    print(f"  • Claude: https://console.anthropic.com/settings/keys")
    print(f"  • OpenAI: https://platform.openai.com/api-keys")

check("Provider priority", True, " → ".join(settings.provider_priority))
check("Models", True,
      f"Gemini={settings.gemini_model} | Claude={settings.claude_model} | OpenAI={settings.openai_model}")


# ═══════════════════════════════════════════════════════════════════
section("BƯỚC 2: KIỂM TRA SSL")
# ═══════════════════════════════════════════════════════════════════

try:
    ctx = ssl.create_default_context()
    check("SSL certificates", True, "hệ thống có cert bundle")
except Exception as e:
    check("SSL certificates", False, f"THIẾU — sẽ dùng fallback không verify. Lỗi: {e}")


# ═══════════════════════════════════════════════════════════════════
section("BƯỚC 3: KIỂM TRA KẾT NỐI MẠNG")
# ═══════════════════════════════════════════════════════════════════

endpoints = {
    "Google Gemini":  "https://generativelanguage.googleapis.com/v1beta/models",
    "Anthropic Claude": "https://api.anthropic.com/v1/messages",
    "OpenAI":         "https://api.openai.com/v1/chat/completions",
}

try:
    _ctx = ssl.create_default_context()
except Exception:
    _ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
    _ctx.check_hostname = False
    _ctx.verify_mode = ssl.CERT_NONE

for name, url in endpoints.items():
    try:
        urllib.request.urlopen(url, timeout=10, context=_ctx)
        check(name, True, "kết nối OK")
    except urllib.error.HTTPError as e:
        # HTTP error = mạng thông, server trả lỗi (bình thường vì chưa gửi body)
        check(name, True, f"mạng thông (HTTP {e.code})")
    except Exception as e:
        check(name, False, f"KHÔNG KẾT NỐI ĐƯỢC: {e}")


# ═══════════════════════════════════════════════════════════════════
section("BƯỚC 4: THỬ GỌI AI THẬT")
# ═══════════════════════════════════════════════════════════════════

test_question = "1 + 1 = ?"

if gemini_key:
    print(f"\n  Thử gọi Gemini ({settings.gemini_model})...")
    try:
        from app.core.providers.gemini_provider import GeminiProvider
        from app.core.models import ProviderResult
        p = GeminiProvider(api_key=gemini_key)
        result = p.generate(
            "Trả lời ngắn gọn bằng tiếng Việt. Chỉ trả JSON: {\"answer\": \"...\"}",
            test_question, max_output_tokens=100)
        check("Gemini gọi THÀNH CÔNG", True, f"tokens={result.tokens_used}")
        print(f"    Response: {result.text[:200]}")
    except Exception as e:
        check("Gemini gọi THẤT BẠI", False, str(e))

if claude_key:
    print(f"\n  Thử gọi Claude ({settings.claude_model})...")
    try:
        from app.core.providers.claude_provider import ClaudeProvider
        p = ClaudeProvider(api_key=claude_key)
        result = p.generate(
            "Trả lời ngắn gọn bằng tiếng Việt. Chỉ trả JSON: {\"answer\": \"...\"}",
            test_question, max_output_tokens=100)
        check("Claude gọi THÀNH CÔNG", True, f"tokens={result.tokens_used}")
        print(f"    Response: {result.text[:200]}")
    except Exception as e:
        check("Claude gọi THẤT BẠI", False, str(e))

if openai_key:
    print(f"\n  Thử gọi OpenAI ({settings.openai_model})...")
    try:
        from app.core.providers.openai_provider import OpenAIProvider
        p = OpenAIProvider(api_key=openai_key)
        result = p.generate(
            "Trả lời ngắn gọn bằng tiếng Việt. Chỉ trả JSON: {\"answer\": \"...\"}",
            test_question, max_output_tokens=100)
        check("OpenAI gọi THÀNH CÔNG", True, f"tokens={result.tokens_used}")
        print(f"    Response: {result.text[:200]}")
    except Exception as e:
        check("OpenAI gọi THẤT BẠI", False, str(e))

if not has_any_key:
    print(f"\n  {WARN} Bỏ qua test gọi AI — không có key nào.")


# ═══════════════════════════════════════════════════════════════════
section("BƯỚC 5: TEST PIPELINE ĐẦY ĐỦ (dùng provider có sẵn)")
# ═══════════════════════════════════════════════════════════════════

from app.core.answer_service import AnswerService
from app.core.models import (Question, StudentProfile, EducationLevel,
                              ExplanationStyle)

svc = AnswerService()
active_providers = [p.name for p in svc.providers.providers]
print(f"  Providers đang hoạt động: {active_providers}")

profile = StudentProfile(user_id="test", education_level=EducationLevel.HIGH_SCHOOL,
                          preferred_style=ExplanationStyle.STEP_BY_STEP)
q = Question(user_id="test", content_text="Giải phương trình x² - 9 = 0")
answer = svc.answer_question(q, profile)

check("Pipeline chạy thành công", q.status.value == "answered",
      f"status={q.status.value}")
check("Có đáp án", bool(answer.content_data.direct_answer),
      f"answer='{answer.content_data.direct_answer[:80]}'")
check("Model dùng", True, f"ai_model_version={answer.ai_model_version}")
check("Tokens dùng", True, f"api_tokens_used={answer.api_tokens_used}")
is_real = answer.ai_model_version not in ("mock-1.0", "cache:exact", "cache:similarity")
if is_real:
    print(f"\n  {PASS} ĐANG DÙNG AI THẬT ({answer.ai_model_version})!")
else:
    print(f"\n  {WARN} Đang dùng {answer.ai_model_version} — điền API key vào .env để dùng AI thật.")

print(f"\n{'═' * 60}")
print(f"  CHẨN ĐOÁN HOÀN TẤT")
print(f"{'═' * 60}\n")
