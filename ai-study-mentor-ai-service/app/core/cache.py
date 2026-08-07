"""
cache.py — Cache 2 tầng để tiết kiệm chi phí AI (yêu cầu "AI Cost Management").

Tầng 1 — EXACT MATCH: chuẩn hoá văn bản -> SHA-256 (lưu vào cột question_hash
          trong bảng Questions). Câu hỏi trùng 100% -> trả ngay, 0 đồng.
Tầng 2 — SIMILARITY: so khớp tương đồng (Jaccard trên n-gram ký tự) để bắt
          các câu "gần giống" ("giải pt x^2-4=0" vs "giải phương trình x^2 - 4 = 0").
          Vượt ngưỡng AI_SIMILARITY_THRESHOLD -> tái sử dụng đáp án cũ.

THIẾT KẾ MỞ RỘNG: CacheBackend là interface — bản demo dùng InMemoryBackend,
khi lên production chỉ cần viết RedisBackend / PostgresBackend cài đúng 4 hàm,
KHÔNG sửa logic. (Lại là Open/Closed Principle.)

Ghi chú cho tương lai: khi có ngân sách, thay SimilarityIndex bằng
embedding + pgvector sẽ bắt tương đồng NGỮ NGHĨA tốt hơn. Interface giữ nguyên.
"""

from __future__ import annotations

import hashlib
import re
import time
import unicodedata
from abc import ABC, abstractmethod
from typing import Optional

from ..config import settings


# ── Chuẩn hoá văn bản ──────────────────────────────────────────────
# Các cụm từ đệm/lịch sự KHÔNG mang nội dung học thuật — lọc bỏ trước khi
# hash/so khớp để "giải x^2-4=0" và "giải x^2-4=0 giúp mình với ạ" trùng nhau.
# Danh sách để ở đây, dễ bổ sung mà không sửa logic.
_FILLER_PATTERNS = [
    r"\bgiúp\s+(mình|em|tớ|tui|tôi|anh|chị|con)\b",
    r"\bcho\s+(mình|em|tớ|tui|tôi)\s+hỏi\b",
    r"\bmọi\s+người\s+ơi\b",
    r"\b(với|vậy|nha|nhé|nhá|ạ|ơi|đi)\b\s*$",   # từ đệm ở cuối câu (lặp nhiều lần)
    r"\bplease\b", r"\bpls\b", r"\bhelp\s+me\b",
]


def normalize_text(text: str) -> str:
    """Chuẩn hoá để 2 cách gõ khác nhau của cùng 1 câu hỏi cho ra cùng kết quả."""
    text = unicodedata.normalize("NFC", text)      # chuẩn hoá Unicode tiếng Việt
    text = text.lower().strip()
    text = re.sub(r"[\u201c\u201d]", '"', text)
    text = re.sub(r"[\u2018\u2019]", "'", text)
    text = re.sub(r"[?!.,;:]+\s*$", "", text)      # bỏ dấu câu cuối TRƯỚC khi lọc từ đệm
    # Lọc từ đệm (lặp để bắt chuỗi "giúp mình với ạ" -> rỗng dần)
    for _ in range(3):
        for pat in _FILLER_PATTERNS:
            text = re.sub(pat, " ", text).strip()
    # Bỏ khoảng trắng quanh toán tử để "x^2 - 4 = 0" == "x^2-4=0"
    text = re.sub(r"\s*([=+\-*/^<>()])\s*", r"\1", text)
    text = re.sub(r"\s+", " ", text).strip()       # gộp khoảng trắng
    return text


def question_hash(text: str) -> str:
    """SHA-256 của văn bản đã chuẩn hoá — lưu vào Questions.question_hash."""
    return hashlib.sha256(normalize_text(text).encode("utf-8")).hexdigest()


def _char_ngrams(text: str, n: int = 3) -> set:
    t = normalize_text(text)
    if len(t) < n:
        return {t} if t else set()
    return {t[i:i + n] for i in range(len(t) - n + 1)}


def similarity(a: str, b: str) -> float:
    """Độ tương đồng trên 3-gram ký tự. Hoạt động tốt với tiếng Việt,
    công thức toán, code — không cần tách từ.

    Kết hợp 2 độ đo:
    - Jaccard       = |A∩B| / |A∪B|        (phạt khi 2 câu khác nhau nhiều)
    - Overlap coef. = |A∩B| / min(|A|,|B|)  (bắt được "câu lõi giống nhau
                       nhưng 1 câu thêm vài chữ thừa" như 'giúp mình')
    Lấy trung bình có trọng số nghiêng về overlap để phục vụ mục đích cache.
    """
    ga, gb = _char_ngrams(a), _char_ngrams(b)
    if not ga or not gb:
        return 0.0
    inter = len(ga & gb)
    jaccard = inter / len(ga | gb)
    overlap = inter / min(len(ga), len(gb))
    return 0.4 * jaccard + 0.6 * overlap


# ── Backend trừu tượng ─────────────────────────────────────────────
class CacheBackend(ABC):
    @abstractmethod
    def get(self, key: str) -> Optional[dict]: ...

    @abstractmethod
    def set(self, key: str, value: dict, ttl_seconds: int) -> None: ...

    @abstractmethod
    def all_entries(self) -> list:
        """Trả về [(key, value_dict)] cho tầng similarity. Backend thật nên
        giới hạn theo subject để quét nhanh."""

    @abstractmethod
    def clear(self) -> None: ...


class InMemoryBackend(CacheBackend):
    """Backend mặc định cho dev/test. Production: thay bằng Redis/Postgres."""

    def __init__(self):
        self._store: dict[str, tuple[float, dict]] = {}

    def get(self, key: str) -> Optional[dict]:
        item = self._store.get(key)
        if item is None:
            return None
        expires_at, value = item
        if time.time() > expires_at:
            del self._store[key]
            return None
        return value

    def set(self, key: str, value: dict, ttl_seconds: int) -> None:
        self._store[key] = (time.time() + ttl_seconds, value)

    def all_entries(self) -> list:
        now = time.time()
        return [(k, v) for k, (exp, v) in list(self._store.items()) if now <= exp]

    def clear(self) -> None:
        self._store.clear()


# ── Cache 2 tầng ───────────────────────────────────────────────────
class AnswerCache:
    def __init__(self, backend: Optional[CacheBackend] = None):
        self.backend = backend or InMemoryBackend()

    def lookup(self, question_text: str, subject: Optional[str] = None) -> Optional[dict]:
        """Trả về dict {answer_content, original_question, ...} nếu trúng cache."""
        if not settings.cache_enabled or not question_text.strip():
            return None

        # Tầng 1: exact hash
        key = question_hash(question_text)
        hit = self.backend.get(key)
        if hit is not None:
            return {**hit, "cache_tier": "exact"}

        # Tầng 2: similarity
        best, best_score = None, 0.0
        for _, entry in self.backend.all_entries():
            if subject and entry.get("subject") and entry["subject"] != subject:
                continue  # khác môn thì khỏi so — tiết kiệm thời gian quét
            score = similarity(question_text, entry.get("original_question", ""))
            if score > best_score:
                best, best_score = entry, score
        if best is not None and best_score >= settings.similarity_threshold:
            return {**best, "cache_tier": "similarity", "similarity_score": round(best_score, 4)}
        return None

    def store(self, question_text: str, answer_content: dict, subject: str = "") -> str:
        key = question_hash(question_text)
        self.backend.set(key, {
            "original_question": question_text,
            "answer_content": answer_content,
            "subject": subject,
            "cached_at": time.time(),
        }, settings.cache_ttl_seconds)
        return key
