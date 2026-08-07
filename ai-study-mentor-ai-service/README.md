# AI Study Mentor — AI Service Module

Module AI cho ứng dụng **AI Study Mentor** (BrightPath Learning — Unit 22: Application Development).
Đảm nhiệm toàn bộ phần trí tuệ nhân tạo: trả lời câu hỏi học tập, sinh quiz luyện tập,
chấm điểm tức thì, và phân tích tiến độ học tập.

## 1. Chạy thử ngay (không cần API key)

```bash
python3 demo.py                          # demo end-to-end bằng MockProvider
python3 -m unittest discover tests -v    # 20 unit test, chạy offline 100%
```

## 2. Chạy thật với Gemini/OpenAI

```bash
cp .env.example .env       # điền GEMINI_API_KEY (Google AI Studio có bậc miễn phí)
pip install -r requirements.txt
export $(grep -v '^#' .env | xargs)      # hoặc dùng python-dotenv
uvicorn app.main:app --reload --port 8000
# Mở http://localhost:8000/docs để test API tương tác
```

## 3. Kiến trúc — vì sao "linh hoạt và dùng lâu dài"

```
Mobile App (Android/iOS)
        │  HTTP/JSON
        ▼
┌──────────────────────────────  app/main.py (FastAPI — lớp vỏ mỏng)
│  /ai/answer  /ai/quiz/generate  /ai/quiz/grade  /ai/insights
└──────┬───────────────────────
       ▼
┌──────────────────────────────  app/core  (THUẦN PYTHON, không phụ thuộc framework)
│  AnswerService ──► Moderation ──► AnswerCache ──► PromptBuilder
│  QuizService              (2 tầng: exact hash + similarity)
│  InsightService
│        │
│        ▼
│  ProviderManager  (retry + failover tự động theo AI_PROVIDER_PRIORITY)
│   ├── GeminiProvider   ┐
│   ├── OpenAIProvider   ├── cùng cài interface AIProvider
│   └── MockProvider     ┘    (thêm AI mới = thêm 1 file + 1 dòng registry)
└──────────────────────────────
```

Các quyết định thiết kế phục vụ bảo trì dài hạn:

| Quyết định | Lợi ích lâu dài |
|---|---|
| **AIProvider trừu tượng** (`providers/base.py`) | Gemini đổi giá? Model mới ra? Viết 1 provider mới, đổi 1 biến env — không sửa logic nghiệp vụ (Open/Closed Principle) |
| **Failover tự động** (`provider_manager.py`) | 1 provider sập, app vẫn chạy; retry với backoff cho lỗi tạm thời (429/5xx) |
| **AI bắt buộc trả JSON theo schema cố định** | Mobile render ổn định bất kể dùng model nào; đổi AI không vỡ UI |
| **`extract_json` lì đòn** | Model trả thêm ``` hay lời dẫn vẫn parse được — pipeline không bao giờ vỡ |
| **Cache 2 tầng + lọc từ đệm tiếng Việt** | "giải x²−4=0" và "giải x²−4=0 giúp mình với ạ" → cùng 1 đáp án, 0 token. Câu KHÁC đề (x²−9=0) được kiểm chứng KHÔNG bị trả nhầm |
| **CacheBackend trừu tượng** | Demo dùng in-memory; production viết RedisBackend/PostgresBackend cài đúng 4 hàm |
| **Mọi cấu hình trong `config.py` + env** | Tinh chỉnh không cần deploy lại code |
| **Lõi không phụ thuộc FastAPI** | Sau này đổi sang Django/Express chỉ viết lại lớp vỏ `main.py` |
| **Mọi lỗi "hạ cánh mềm"** | AI sập → thông báo lịch sự + insight fallback từ số liệu thô; không bao giờ ném exception thô lên app |

## 4. Khớp với ERD của nhóm

| Code | Bảng trong ERD |
|---|---|
| `Question` (question_hash, extracted_text_from_image, status, subject_id) | `Questions` |
| `AIAnswer` (content_data JSONB, **is_cached_response**, **api_tokens_used**, ai_model_version) | `AI_Answers` |
| `QuizQuestion` (question_type, question_payload JSONB, user_answer, is_correct, instant_feedback) | `Quiz_Questions` |
| `StudentProfile` (education_level, preferred_style) | `Users` |

Backend chỉ cần lấy dict từ service rồi INSERT vào đúng bảng — không cần chuyển đổi.

## 5. Khớp với yêu cầu đề bài (Functional Requirements)

- **AI Question Submission**: text + ảnh base64 (Gemini/GPT-4o đọc trực tiếp ảnh — không cần OCR riêng, ít lỗi hơn với công thức toán)
- **AI Answer Generation**: tự nhận diện môn + độ khó; giải từng bước; giải thích công thức; đáp án cuối rõ ràng; ngôn ngữ theo trình độ (THCS/THPT/ĐH) và phong cách (short/detailed/step_by_step)
- **Answer Improvement & Learning Support**: simplified_explanation, alternative_approaches, key_concepts_summary, common_mistakes, follow_up_questions — trả về trong CÙNG 1 lần gọi API (tiết kiệm ~50% chi phí so với gọi 2 lần)
- **AI-Generated Practice Questions**: MCQ / short answer / fill-in-blank + instant feedback; MCQ và fill-in-blank chấm cục bộ **0 token**, chỉ short answer mới nhờ AI chấm ngữ nghĩa
- **Progress Tracking**: AI insights kiểu "Bạn hỏi nhiều về phương trình đại số" + gợi ý ôn tập
- **AI Cost Management** (ràng buộc dự án): cache exact + similarity, theo dõi `api_tokens_used` từng câu trả lời, mock provider cho dev/test miễn phí
- **Abuse detection**: chặn spam, prompt injection, câu quá dài ở lớp rẻ (0 chi phí) + AI từ chối nội dung ngoài học tập ở lớp prompt

## 6. Hướng nâng cấp tương lai (đã chừa sẵn chỗ)

1. **Semantic cache bằng embeddings + pgvector** — thay thuật toán trong `cache.similarity()`, interface giữ nguyên.
2. **Streaming câu trả lời** — thêm hàm `generate_stream()` vào `AIProvider`.
3. **Rate limit theo user** — thêm middleware ở lớp FastAPI, lõi không đổi.
4. **RedisBackend cho cache** — cài 4 hàm của `CacheBackend`.

## 7. Cấu trúc thư mục

```
app/
├── config.py                 # mọi cấu hình (đọc từ env)
├── main.py                   # lớp API HTTP (FastAPI)
├── core/                     # LÕI — thuần Python stdlib
│   ├── models.py             # dataclass khớp ERD
│   ├── answer_service.py     # pipeline trả lời chính
│   ├── quiz_service.py       # sinh quiz + chấm điểm
│   ├── insight_service.py    # AI insights cho dashboard
│   ├── prompt_builder.py     # prompt cá nhân hoá theo trình độ/phong cách
│   ├── cache.py              # cache 2 tầng (cost management)
│   ├── moderation.py         # abuse detection
│   ├── provider_manager.py   # retry + failover
│   └── providers/            # Gemini / OpenAI / Mock (+ AI tương lai)
├── utils/json_extract.py     # parse JSON bền bỉ từ output AI
tests/test_ai_service.py      # 20 unit test offline
demo.py                       # demo end-to-end
```
