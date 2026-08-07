package com.brightpath.aimentor.service;

import com.brightpath.aimentor.dto.AiAnswerResponse;
import com.brightpath.aimentor.dto.AskQuestionRequest;
import com.brightpath.aimentor.entity.*;
import com.brightpath.aimentor.repository.*;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.*;

@Service
public class QuestionService {
    private static final Logger log = LoggerFactory.getLogger(QuestionService.class);
    private final QuestionRepository questionRepo;
    private final AiAnswerRepository answerRepo;
    private final UserRepository userRepo;
    private final GeminiService gemini;
    private final ActivityLogService logService;
    private final ObjectMapper mapper = new ObjectMapper();

    public QuestionService(QuestionRepository qr, AiAnswerRepository ar, UserRepository ur,
                           GeminiService gs, ActivityLogService ls) {
        this.questionRepo=qr; this.answerRepo=ar; this.userRepo=ur; this.gemini=gs; this.logService=ls;
    }

    public AiAnswerResponse askQuestion(String userId, AskQuestionRequest req) {
        User user = userRepo.findById(userId)
                .orElseThrow(() -> new RuntimeException("User không tồn tại."));

        String text = req.getContentText() != null ? req.getContentText().trim() : "";
        if (text.isEmpty() && (req.getImageBase64() == null || req.getImageBase64().isBlank())) {
            throw new RuntimeException("Vui lòng nhập câu hỏi.");
        }

        String hash = hashQuestion(text);

        // ── Cache: tìm answer cũ từ hash (chỉ text, không ảnh) ──
        String cachedContent = null;
        if (!text.isEmpty() && req.getImageBase64() == null) {
            try {
                List<Question> cachedQuestions = questionRepo.findByQuestionHashOrderByCreatedAtDesc(hash);
                for (Question cq : cachedQuestions) {
                    Optional<AiAnswer> ca = answerRepo.findByQuestionId(cq.getQuestionId());
                    if (ca.isPresent() && ca.get().getContentData() != null && !ca.get().getContentData().isBlank()) {
                        cachedContent = ca.get().getContentData();
                        log.info("Cache HIT for hash={}", hash.substring(0, Math.min(16, hash.length())));
                        break;
                    }
                }
            } catch (Exception e) {
                log.warn("Cache lookup failed: {}", e.getMessage());
                // Không crash — tiếp tục gọi AI
            }
        }

        // ── LUÔN tạo Question mới cho user hiện tại ──
        Question q = new Question();
        q.setQuestionId(UUID.randomUUID().toString());
        q.setUserId(userId);
        q.setQuestionText(text.isEmpty() ? "(ảnh)" : text);
        q.setQuestionHash(hash);
        q.setImageUrl(req.getImageBase64() != null ? "base64-upload" : null);
        q.setStatus("Pending");

        try {
            questionRepo.save(q);
        } catch (Exception e) {
            log.error("Lỗi lưu câu hỏi: {}", e.getMessage());
            throw new RuntimeException("Lỗi lưu câu hỏi. Thử lại sau.");
        }

        // ── Nếu cache có → dùng luôn, KHÔNG gọi AI ──
        String rawResponse;
        boolean isCached;
        if (cachedContent != null) {
            rawResponse = cachedContent;
            isCached = true;
        } else {
            // ── Gọi Gemini ──
            isCached = false;
            String sys = gemini.buildSystemPrompt(
                    user.getEducationLevel() != null ? user.getEducationLevel() : "high_school",
                    user.getPreferredStyle() != null ? user.getPreferredStyle() : "step_by_step");
            try {
                if (req.getImageBase64() != null && !req.getImageBase64().isBlank()) {
                    String up = text.isEmpty() ? "Đọc đề bài trong ảnh và giải đáp." : "Câu hỏi (kèm ảnh):\n" + text;
                    String mime = req.getImageMimeType() != null ? req.getImageMimeType() : "image/jpeg";
                    rawResponse = gemini.generateWithImage(sys, up, req.getImageBase64(), mime);
                } else {
                    rawResponse = gemini.generate(sys, "Câu hỏi của học sinh:\n" + text);
                }
            } catch (Exception e) {
                q.setStatus("Failed");
                try { questionRepo.save(q); } catch (Exception ignored) {}
                String msg = e.getMessage() != null ? e.getMessage() : "";
                if (msg.contains("429") || msg.contains("Too Many") || msg.contains("bận")) {
                    throw new RuntimeException("AI đang bận, vui lòng thử lại sau 1 phút.");
                } else if (msg.contains("403") || msg.contains("401")) {
                    throw new RuntimeException("API key không hợp lệ.");
                } else {
                    throw new RuntimeException("AI tạm thời không khả dụng. Thử lại sau.");
                }
            }
        }

        // ── Lưu answer cho question CỦA USER NÀY ──
        q.setStatus("Resolved");
        try { questionRepo.save(q); } catch (Exception ignored) {}

        int tokensUsed = isCached ? 0 : (rawResponse != null ? rawResponse.length() / 4 : 0);
        AiAnswer answer = new AiAnswer();
        answer.setAnswerId(UUID.randomUUID().toString());
        answer.setQuestionId(q.getQuestionId());
        answer.setContentData(rawResponse != null ? rawResponse : "{}");
        answer.setIsCachedResponse(isCached);
        answer.setApiTokensUsed(tokensUsed);
        answer.setAiModelVersion(isCached ? "cache" : "gemini-2.0-flash");

        try {
            answerRepo.save(answer);
        } catch (Exception e) {
            log.error("Lỗi lưu answer: {}", e.getMessage());
            // Vẫn trả kết quả cho user dù không lưu được
        }

        // ── Log + XP ──
        try {
            logService.logActivity(userId, "Asked_Question");
            user.setXpPoints((user.getXpPoints() != null ? user.getXpPoints() : 0) + 10);
            userRepo.save(user);
        } catch (Exception e) {
            log.warn("Lỗi cộng XP: {}", e.getMessage());
        }

        return parseAnswer(q.getQuestionId(), rawResponse, isCached, tokensUsed,
                answer.getAiModelVersion());
    }

    public List<Map<String, Object>> getHistory(String userId) {
        List<Map<String, Object>> result = new ArrayList<>();
        try {
            List<Question> questions = questionRepo.findByUserIdOrderByCreatedAtDesc(userId);
            for (Question q : questions) {
                Map<String, Object> item = new LinkedHashMap<>();
                item.put("questionId", q.getQuestionId());
                item.put("questionText", q.getQuestionText());
                item.put("status", q.getStatus());
                item.put("createdAt", q.getCreatedAt() != null ? q.getCreatedAt().toString() : "");
                try {
                    answerRepo.findByQuestionId(q.getQuestionId()).ifPresent(a -> {
                        try {
                            JsonNode n = mapper.readTree(a.getContentData());
                            item.put("directAnswer", n.path("direct_answer").asText(""));
                            item.put("subject", n.path("subject").asText(""));
                        } catch (Exception ignored) {}
                    });
                } catch (Exception ignored) {}
                result.add(item);
            }
        } catch (Exception e) {
            log.error("Lỗi lấy lịch sử: {}", e.getMessage());
        }
        return result;
    }

    // ── helpers ──

    private AiAnswerResponse parseAnswer(String qId, String json, boolean cached, int tokens, String model) {
        AiAnswerResponse r = new AiAnswerResponse();
        r.setQuestionId(qId);
        r.setCachedResponse(cached);
        r.setTokensUsed(tokens);
        r.setModel(model);
        try {
            if (json != null && !json.isBlank()) {
                JsonNode n = mapper.readTree(json);
                r.setSubject(n.path("subject").asText("other"));
                r.setDifficulty(n.path("difficulty").asText("basic"));
                r.setDirectAnswer(n.path("direct_answer").asText(""));
                r.setExplanation(n.path("explanation").asText(""));
                r.setSteps(toList(n.path("steps")));
                r.setFormulasOrConcepts(toList(n.path("formulas_or_concepts")));
                r.setSimplifiedExplanation(n.path("simplified_explanation").asText(""));
                r.setAlternativeApproaches(toList(n.path("alternative_approaches")));
                r.setKeyConceptsSummary(toList(n.path("key_concepts_summary")));
                r.setCommonMistakes(toList(n.path("common_mistakes")));
                r.setFollowUpQuestions(toList(n.path("follow_up_questions")));
            }
        } catch (Exception e) {
            r.setExplanation(json != null ? json : "");
        }
        return r;
    }

    private List<String> toList(JsonNode a) {
        List<String> l = new ArrayList<>();
        if (a != null && a.isArray()) a.forEach(e -> l.add(e.asText()));
        return l;
    }

    private String hashQuestion(String text) {
        try {
            String normalized = text.toLowerCase().replaceAll("\\s+", " ").trim();
            byte[] h = MessageDigest.getInstance("SHA-256")
                    .digest(normalized.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : h) sb.append(String.format("%02x", b));
            return sb.toString();
        } catch (Exception e) { return UUID.randomUUID().toString(); }
    }
}
