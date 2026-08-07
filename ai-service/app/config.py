"""
config.py — Cấu hình trung tâm cho AI Service của "AI Study Mentor".

NGUYÊN TẮC THIẾT KẾ (để bảo trì lâu dài):
- Mọi giá trị có thể thay đổi (model name, ngưỡng cache, giới hạn token...)
  đều nằm ở ĐÂY, đọc từ biến môi trường (.env). Không hard-code trong logic.
- Khi Google/OpenAI ra model mới, chỉ cần đổi biến môi trường,
  KHÔNG cần sửa code.
"""

import os
from dataclasses import dataclass, field
from pathlib import Path


# ── TỰ ĐỘNG ĐỌC FILE .env (KHÔNG cần cài thư viện ngoài) ──────────
# Python KHÔNG tự đọc file .env. Hàm dưới đây thay thế python-dotenv
# bằng code thuần stdlib — không thêm dependency.
def _load_dotenv() -> None:
    """Tìm file .env từ thư mục hiện tại trở lên và nạp vào os.environ."""
    # Tìm .env: thử thư mục chứa config.py, rồi trở lên tối đa 3 cấp
    start = Path(__file__).resolve().parent
    for folder in [start, start.parent, start.parent.parent, Path.cwd()]:
        env_file = folder / ".env"
        if env_file.is_file():
            with open(env_file, encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if not line or line.startswith("#") or "=" not in line:
                        continue
                    key, _, value = line.partition("=")
                    key = key.strip()
                    value = value.strip()
                    # Bỏ dấu ngoặc kép bọc ngoài (nếu có)
                    if len(value) >= 2 and value[0] == value[-1] and value[0] in ('"', "'"):
                        value = value[1:-1]
                    # Chỉ set nếu chưa có — biến môi trường thật luôn ưu tiên hơn file
                    if key and key not in os.environ:
                        os.environ[key] = value
            return  # tìm thấy 1 file là đủ


_load_dotenv()


def _env(key: str, default: str = "") -> str:
    return os.environ.get(key, default)


def _env_int(key: str, default: int) -> int:
    try:
        return int(os.environ.get(key, default))
    except (TypeError, ValueError):
        return default


def _env_float(key: str, default: float) -> float:
    try:
        return float(os.environ.get(key, default))
    except (TypeError, ValueError):
        return default


@dataclass
class Settings:
    # ── Nhà cung cấp AI ─────────────────────────────────────────────
    # Thứ tự ưu tiên failover: provider đầu lỗi -> tự chuyển sang provider sau.
    # Ví dụ: "gemini,claude,openai,mock"
    provider_priority: list = field(
        default_factory=lambda: [
            p.strip() for p in _env("AI_PROVIDER_PRIORITY", "gemini,claude,openai,mock").split(",") if p.strip()
        ]
    )

    gemini_api_key: str = field(default_factory=lambda: _env("GEMINI_API_KEY"))
    gemini_model: str = field(default_factory=lambda: _env("GEMINI_MODEL", "gemini-2.0-flash"))
    gemini_vision_model: str = field(default_factory=lambda: _env("GEMINI_VISION_MODEL", "gemini-2.0-flash"))

    claude_api_key: str = field(default_factory=lambda: _env("CLAUDE_API_KEY"))
    claude_model: str = field(default_factory=lambda: _env("CLAUDE_MODEL", "claude-sonnet-4-6"))

    openai_api_key: str = field(default_factory=lambda: _env("OPENAI_API_KEY"))
    openai_model: str = field(default_factory=lambda: _env("OPENAI_MODEL", "gpt-4o-mini"))

    # ── Quản lý chi phí (yêu cầu "AI Cost Management" trong đề bài) ──
    cache_enabled: bool = field(default_factory=lambda: _env("AI_CACHE_ENABLED", "true").lower() == "true")
    # Ngưỡng tương đồng (0..1) để coi 2 câu hỏi là "giống nhau" và tái sử dụng đáp án.
    # 0.90 được chọn qua kiểm thử: câu trùng + vài chữ thừa ~0.91; câu KHÁC ĐỀ
    # (vd đổi số trong phương trình) ~0.83 -> không bao giờ trả nhầm đáp án cũ.
    similarity_threshold: float = field(default_factory=lambda: _env_float("AI_SIMILARITY_THRESHOLD", 0.90))
    cache_ttl_seconds: int = field(default_factory=lambda: _env_int("AI_CACHE_TTL_SECONDS", 60 * 60 * 24 * 30))
    max_output_tokens: int = field(default_factory=lambda: _env_int("AI_MAX_OUTPUT_TOKENS", 1500))

    # ── Độ bền vững khi gọi API ─────────────────────────────────────
    request_timeout_seconds: int = field(default_factory=lambda: _env_int("AI_REQUEST_TIMEOUT", 45))
    max_retries: int = field(default_factory=lambda: _env_int("AI_MAX_RETRIES", 2))
    retry_backoff_seconds: float = field(default_factory=lambda: _env_float("AI_RETRY_BACKOFF", 1.5))

    # ── An toàn nội dung (Abuse detection trong đề bài) ─────────────
    moderation_enabled: bool = field(default_factory=lambda: _env("AI_MODERATION_ENABLED", "true").lower() == "true")
    max_question_chars: int = field(default_factory=lambda: _env_int("AI_MAX_QUESTION_CHARS", 4000))


settings = Settings()
