package com.brightpath.aimentor.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;
import java.time.Duration;
import java.util.*;

/**
 * Gọi Google Gemini API trực tiếp.
 *
 * Tất cả logic prompt engineering (cá nhân hoá theo trình độ, ép JSON schema,
 * nhận diện môn học...) đều nằm ở đây — đúng như module AI Python bên trên
 * nhưng viết lại bằng Java cho Spring Boot.
 */
@Service

public class GeminiService {
    private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(GeminiService.class);

    private static final String API_BASE = "https://generativelanguage.googleapis.com/v1beta/models";
    private final WebClient webClient;
    private final ObjectMapper mapper = new ObjectMapper();

    @Value("${gemini.api-key}")      private String apiKey;
    @Value("${gemini.model}")         private String model;
    @Value("${gemini.vision-model}")  private String visionModel;
    @Value("${gemini.timeout-seconds}") private int timeout;
    @Value("${gemini.max-output-tokens}") private int maxTokens;

    // Safety settings — tắt filter để câu hỏi học thuật không bị chặn
    private static final List<Map<String, String>> SAFETY_OFF = List.of(
        Map.of("category", "HARM_CATEGORY_HARASSMENT", "threshold", "BLOCK_NONE"),
        Map.of("category", "HARM_CATEGORY_HATE_SPEECH", "threshold", "BLOCK_NONE"),
        Map.of("category", "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold", "BLOCK_NONE"),
        Map.of("category", "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold", "BLOCK_NONE")
    );

    public GeminiService() {
        this.webClient = WebClient.builder()
                .codecs(cfg -> cfg.defaultCodecs().maxInMemorySize(5 * 1024 * 1024))
                .build();
    }

    // ── System prompt cá nhân hoá (giống prompt_builder.py) ────────

    private static final Map<String, String> LEVEL_GUIDE = Map.of(
        "middle_school", "Học sinh THCS (lớp 6-9). Dùng từ ngữ đơn giản, ví dụ đời thường.",
        "high_school",   "Học sinh THPT (lớp 10-12). Dùng thuật ngữ phổ thông, bám SGK.",
        "university",    "Sinh viên ĐH. Trình bày chuyên sâu, ký hiệu toán học chuẩn."
    );

    private static final Map<String, String> STYLE_GUIDE = Map.of(
        "short",        "Trả lời NGẮN GỌN, đi thẳng trọng tâm.",
        "detailed",     "Trả lời CHI TIẾT, giải thích bản chất và bối cảnh.",
        "step_by_step", "Trả lời TỪNG BƯỚC, đánh số rõ ràng."
    );

    private static final String ANSWER_SCHEMA = """
    {
      "subject": "mathematics|science|programming|history|languages|other",
      "difficulty": "basic|intermediate|advanced",
      "direct_answer": "Đáp án cuối cùng, rõ ràng",
      "explanation": "Lời giải chính",
      "steps": ["Bước 1", "Bước 2"],
      "formulas_or_concepts": ["Công thức đã dùng"],
      "simplified_explanation": "Giải thích đơn giản hơn",
      "alternative_approaches": ["Cách giải khác"],
      "key_concepts_summary": ["Khái niệm cốt lõi"],
      "common_mistakes": ["Lỗi thường gặp"],
      "follow_up_questions": ["Câu luyện tập"]
    }""";

    public String buildSystemPrompt(String educationLevel, String preferredStyle) {
        String level = LEVEL_GUIDE.getOrDefault(educationLevel, LEVEL_GUIDE.get("high_school"));
        String style = STYLE_GUIDE.getOrDefault(preferredStyle, STYLE_GUIDE.get("step_by_step"));

        return "Bạn là \"AI Study Mentor\" — gia sư AI thông minh, hỗ trợ học sinh sinh viên HỌC TẬP.\n\n" +
               "ĐỐI TƯỢNG: " + level + "\n" +
               "PHONG CÁCH: " + style + "\n" +
               "NGÔN NGỮ: tiếng Việt.\n\n" +
               "QUY TẮC:\n" +
               "1. CHÍNH XÁC là ưu tiên #1 — không bịa đáp án, công thức.\n" +
               "2. Giải bài: trình bày bước logic + công thức + ĐÁP ÁN CUỐI.\n" +
               "3. Tự xác định môn học (subject) và độ khó (difficulty).\n" +
               "4. Hướng dẫn để HIỂU, không chỉ cho đáp án.\n" +
               "5. Nếu câu hỏi KHÔNG liên quan học tập (chat linh tinh, hỏi chuyện cá nhân, nội dung không phù hợp): " +
               "vẫn trả JSON bình thường nhưng đặt subject=\"other\", direct_answer=\"Câu hỏi này nằm ngoài phạm vi học tập. Hãy hỏi mình về Toán, Lý, Hoá, Anh, Sử, CNTT hoặc bất kỳ môn học nào nhé!\", " +
               "explanation giải thích ngắn gọn vì sao không trả lời, và follow_up_questions gợi ý 2-3 câu hỏi học tập hay.\n" +
               "6. Ảnh mờ/thiếu → nêu rõ, giải với giả định hợp lý.\n\n" +
               "QUAN TRỌNG: LUÔN trả JSON hợp lệ, KHÔNG BAO GIỜ từ chối hoàn toàn hay trả text rỗng.\n\n" +
               "CHỈ trả về MỘT JSON hợp lệ theo schema:\n" + ANSWER_SCHEMA;
    }

    // ── Quiz prompt ────────────────────────────────────────────────

    private static final String QUIZ_SCHEMA = """
    {
      "questions": [
        {
          "question_type": "multiple_choice|short_answer|fill_in_blank",
          "question": "Nội dung câu hỏi",
          "options": ["A", "B", "C", "D"],
          "correct_answer": "Đáp án đúng",
          "explanation": "Giải thích"
        }
      ]
    }""";

    public String buildQuizSystemPrompt(String educationLevel) {
        String level = LEVEL_GUIDE.getOrDefault(educationLevel, LEVEL_GUIDE.get("high_school"));
        return "Bạn là AI Study Mentor, tạo câu hỏi luyện tập.\n" +
               "ĐỐI TƯỢNG: " + level + "\n" +
               "NGÔN NGỮ: tiếng Việt.\n" +
               "Câu hỏi CHÍNH XÁC, bám chủ đề, đáp án đúng.\n" +
               "\"options\" chỉ bắt buộc với multiple_choice (4 lựa chọn).\n" +
               "CHỈ trả JSON:\n" + QUIZ_SCHEMA;
    }

    // ── Gọi Gemini API ────────────────────────────────────────────

    public String generate(String systemPrompt, String userPrompt) {
        String url = API_BASE + "/" + model + ":generateContent?key=" + apiKey;

        Map<String, Object> body = Map.of(
            "systemInstruction", Map.of("parts", List.of(Map.of("text", systemPrompt))),
            "contents", List.of(Map.of("role", "user", "parts", List.of(Map.of("text", userPrompt)))),
            "generationConfig", Map.of("maxOutputTokens", maxTokens, "temperature", 0.4,
                                       "responseMimeType", "application/json"),
            "safetySettings", SAFETY_OFF
        );

        return callGemini(url, body);
    }

    public String generateWithImage(String systemPrompt, String userPrompt,
                                     String imageBase64, String mimeType) {
        String url = API_BASE + "/" + visionModel + ":generateContent?key=" + apiKey;

        Map<String, Object> body = Map.of(
            "systemInstruction", Map.of("parts", List.of(Map.of("text", systemPrompt))),
            "contents", List.of(Map.of("role", "user", "parts", List.of(
                Map.of("inlineData", Map.of("mimeType", mimeType, "data", imageBase64)),
                Map.of("text", userPrompt)
            ))),
            "generationConfig", Map.of("maxOutputTokens", maxTokens, "temperature", 0.4,
                                       "responseMimeType", "application/json"),
            "safetySettings", SAFETY_OFF
        );

        return callGemini(url, body);
    }

    private String callGemini(String url, Map<String, Object> body) {
        if (apiKey == null || apiKey.isBlank()) {
            log.warn("GEMINI_API_KEY chưa được cấu hình — trả mock response");
            return MOCK_RESPONSE;
        }

        try {
            String responseBody = webClient.post()
                    .uri(url)
                    .header("Content-Type", "application/json")
                    .bodyValue(body)
                    .retrieve()
                    .bodyToMono(String.class)
                    .timeout(Duration.ofSeconds(timeout))
                    .block();

            JsonNode root = mapper.readTree(responseBody);

            // Check safety filter block
            JsonNode feedback = root.path("promptFeedback");
            if (feedback.has("blockReason")) {
                log.error("Gemini safety block: {}", feedback);
                throw new RuntimeException("Bị Gemini safety filter chặn: " + feedback.get("blockReason").asText());
            }

            JsonNode candidates = root.path("candidates");
            if (candidates.isEmpty() || !candidates.isArray() || candidates.size() == 0) {
                log.error("Gemini trả response rỗng: {}", responseBody);
                throw new RuntimeException("Gemini không trả kết quả.");
            }

            return candidates.get(0).path("content").path("parts").get(0).path("text").asText();

        } catch (Exception e) {
            log.error("Lỗi gọi Gemini: {}", e.getMessage());
            String errMsg = e.getMessage() != null ? e.getMessage() : "unknown";
            log.error("Gemini error: {}", errMsg);
            if (errMsg.contains("429") || errMsg.contains("Too Many")) {
                throw new RuntimeException("AI đang bận, vui lòng thử lại sau 1 phút.");
            }
            throw new RuntimeException("AI tạm thời không khả dụng.", e);
        }
    }

    // Mock response khi chưa có API key — app vẫn chạy được để dev frontend
    private static final String MOCK_RESPONSE = """
    {
      "subject": "other",
      "difficulty": "basic",
      "direct_answer": "[DEMO] Hệ thống đang chạy ở chế độ demo (chưa cấu hình Gemini API key).",
      "explanation": "Vui lòng điền gemini.api-key trong application.properties để dùng AI thật.",
      "steps": [],
      "formulas_or_concepts": [],
      "simplified_explanation": "Cần cấu hình API key.",
      "alternative_approaches": [],
      "key_concepts_summary": [],
      "common_mistakes": [],
      "follow_up_questions": []
    }""";
}
