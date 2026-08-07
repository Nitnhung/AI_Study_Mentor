"""
check_setup.py — Kiểm tra cài đặt từng bước.
Chạy: python3 check_setup.py
File này giúp cả nhóm chẩn đoán lỗi TRƯỚC KHI chạy app.
"""

import os
import sys
from pathlib import Path

print("=" * 60)
print("  KIỂM TRA CÀI ĐẶT AI STUDY MENTOR — AI SERVICE")
print("=" * 60)

errors = 0

# ── Bước 1: Kiểm tra file .env tồn tại ─────────────────────────
print("\n🔍 Bước 1: Tìm file .env")
env_paths = [
    Path(__file__).resolve().parent / ".env",
    Path.cwd() / ".env",
]
env_found = None
for p in env_paths:
    if p.is_file():
        env_found = p
        break

if env_found:
    print(f"   ✅ Tìm thấy: {env_found}")
else:
    print(f"   ❌ KHÔNG tìm thấy file .env!")
    print(f"      Cách sửa:")
    print(f"      1. Copy file .env.example thành .env")
    print(f"      2. Mở .env bằng text editor")
    print(f"      3. Điền API key vào dòng GEMINI_API_KEY=...")
    print(f"      Đường dẫn: {env_paths[0]}")
    errors += 1

# ── Bước 2: Kiểm tra .env có nội dung đúng ──────────────────────
print("\n🔍 Bước 2: Đọc nội dung .env")
if env_found:
    with open(env_found, encoding="utf-8") as f:
        content = f.read()

    # Kiểm tra GEMINI_API_KEY
    gemini_key = ""
    for line in content.splitlines():
        line = line.strip()
        if line.startswith("GEMINI_API_KEY") and "=" in line:
            _, _, val = line.partition("=")
            gemini_key = val.strip().strip('"').strip("'")
            break

    if not gemini_key:
        print("   ❌ GEMINI_API_KEY trống hoặc chưa điền!")
        print("      Mở file .env và thêm dòng:")
        print('      GEMINI_API_KEY=AIzaSy...')
        print("      (lấy key tại https://aistudio.google.com/apikey)")
        errors += 1
    elif gemini_key.startswith("AIzaSy"):
        print(f"   ✅ GEMINI_API_KEY = {gemini_key[:12]}...{gemini_key[-4:]} (đúng format Google)")
    else:
        print(f"   ⚠️  GEMINI_API_KEY = {gemini_key[:10]}... (format lạ, có thể sai)")
        print(f"      Key Gemini thường bắt đầu bằng 'AIzaSy'")
        errors += 1

    # Kiểm tra có lỗi format phổ biến không
    for line in content.splitlines():
        line = line.strip()
        if line.startswith("GEMINI_API_KEY"):
            if " = " in line:
                print("   ⚠️  Phát hiện khoảng trắng quanh dấu '='")
                print(f"      Sai:  GEMINI_API_KEY = AIzaSy...")
                print(f"      Đúng: GEMINI_API_KEY=AIzaSy...")
                errors += 1
            break

# ── Bước 3: Kiểm tra config.py đọc được key ─────────────────────
print("\n🔍 Bước 3: config.py có đọc được key không?")
try:
    # Thêm thư mục hiện tại vào path
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from app.config import settings

    if settings.gemini_api_key:
        key = settings.gemini_api_key
        print(f"   ✅ config.py đọc được: {key[:12]}...{key[-4:]}")
    else:
        print("   ❌ config.py đọc GEMINI_API_KEY = rỗng!")
        print("      Nghĩa là file .env không được nạp đúng.")
        print("      Kiểm tra lại bước 1 và 2.")
        errors += 1

    print(f"\n   Provider priority: {settings.provider_priority}")
    print(f"   Gemini model:     {settings.gemini_model}")
except Exception as e:
    print(f"   ❌ Lỗi import: {e}")
    errors += 1

# ── Bước 4: Thử gọi Gemini API thật ─────────────────────────────
print("\n🔍 Bước 4: Thử gọi Gemini API")
if errors == 0:
    try:
        from app.core.providers.gemini_provider import GeminiProvider

        provider = GeminiProvider()
        print(f"   Gọi {provider.model} với câu test đơn giản...")
        result = provider.generate(
            system_prompt="Trả lời ngắn gọn bằng tiếng Việt.",
            user_prompt="1 + 1 = ?",
            max_output_tokens=100,
        )
        print(f"   ✅ THÀNH CÔNG!")
        print(f"   Phản hồi: {result.text[:200]}")
        print(f"   Tokens:   {result.tokens_used}")
        print(f"   Model:    {result.model_version}")
    except Exception as e:
        error_msg = str(e)
        print(f"   ❌ Gọi API thất bại: {error_msg[:300]}")

        if "403" in error_msg:
            print("\n   NGUYÊN NHÂN: API key không có quyền hoặc chưa bật API.")
            print("   CÁCH SỬA:")
            print("   1. Vào https://aistudio.google.com/apikey")
            print("   2. Tạo key mới (hoặc kiểm tra key cũ còn hoạt động)")
            print("   3. Đảm bảo 'Generative Language API' đã được bật")
        elif "401" in error_msg:
            print("\n   NGUYÊN NHÂN: API key sai hoặc hết hạn.")
            print("   CÁCH SỬA: Tạo key mới tại https://aistudio.google.com/apikey")
        elif "429" in error_msg:
            print("\n   NGUYÊN NHÂN: Vượt giới hạn free tier (quá nhiều request).")
            print("   CÁCH SỬA: Chờ 1 phút rồi thử lại")
        elif "404" in error_msg:
            print("\n   NGUYÊN NHÂN: Model không tồn tại.")
            print("   CÁCH SỬA: Kiểm tra GEMINI_MODEL trong .env")
            print("   Thử đổi thành: gemini-1.5-flash hoặc gemini-2.0-flash")
        elif "Network" in error_msg or "URLError" in error_msg:
            print("\n   NGUYÊN NHÂN: Không có internet hoặc bị firewall chặn.")
            print("   CÁCH SỬA:")
            print("   1. Kiểm tra kết nối mạng")
            print("   2. Thử tắt VPN (nếu đang bật)")
            print("   3. Đảm bảo không bị proxy/firewall chặn googleapis.com")
        else:
            print("\n   Gửi dòng lỗi trên cho nhóm để debug thêm.")
        errors += 1
else:
    print("   ⏭️  Bỏ qua (sửa lỗi ở trên trước)")

# ── Bước 5: Test pipeline end-to-end ────────────────────────────
print("\n🔍 Bước 5: Test pipeline đầy đủ (answer_service)")
if errors == 0:
    try:
        from app.core.answer_service import AnswerService
        from app.core.models import (Question, StudentProfile,
                                     EducationLevel, ExplanationStyle)

        svc = AnswerService()
        profile = StudentProfile(
            user_id="test",
            education_level=EducationLevel.HIGH_SCHOOL,
            preferred_style=ExplanationStyle.STEP_BY_STEP,
        )
        q = Question(user_id="test", content_text="Giải phương trình x^2 - 9 = 0")

        print("   Hỏi: 'Giải phương trình x^2 - 9 = 0'")
        answer = svc.answer_question(q, profile)

        print(f"   ✅ PIPELINE HOẠT ĐỘNG!")
        print(f"   Đáp án:     {answer.content_data.direct_answer}")
        print(f"   Môn:        {answer.content_data.subject}")
        if answer.content_data.steps:
            print(f"   Các bước:")
            for i, s in enumerate(answer.content_data.steps, 1):
                print(f"     {i}. {s}")
        print(f"   Cached:     {answer.is_cached_response}")
        print(f"   Tokens:     {answer.api_tokens_used}")
        print(f"   Model:      {answer.ai_model_version}")
    except Exception as e:
        print(f"   ❌ Pipeline lỗi: {e}")
        errors += 1
else:
    print("   ⏭️  Bỏ qua (sửa lỗi ở trên trước)")

# ── Kết luận ─────────────────────────────────────────────────────
print("\n" + "=" * 60)
if errors == 0:
    print("  ✅ MỌI THỨ OK — AI Service sẵn sàng chạy!")
    print("  Chạy demo:    python3 demo.py")
    print("  Chạy server:  uvicorn app.main:app --reload --port 8000")
else:
    print(f"  ❌ CÓ {errors} VẤN ĐỀ CẦN SỬA")
    print("  Sửa theo hướng dẫn ở trên, rồi chạy lại check_setup.py")
print("=" * 60)
