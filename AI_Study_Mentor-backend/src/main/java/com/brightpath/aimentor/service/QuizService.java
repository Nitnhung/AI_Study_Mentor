package com.brightpath.aimentor.service;

import com.brightpath.aimentor.dto.QuizGenerateRequest;
import com.brightpath.aimentor.entity.*;
import com.brightpath.aimentor.repository.*;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import java.util.*;

@Service
public class QuizService {
    private static final Logger log = LoggerFactory.getLogger(QuizService.class);
    private final QuizRepository quizRepo;
    private final QuizQuestionRepository qqRepo;
    private final UserRepository userRepo;
    private final GeminiService gemini;
    private final ActivityLogService logService;
    private final ObjectMapper mapper = new ObjectMapper();

    public QuizService(QuizRepository qr, QuizQuestionRepository qqr, UserRepository ur, GeminiService gs, ActivityLogService ls) {
        this.quizRepo=qr; this.qqRepo=qqr; this.userRepo=ur; this.gemini=gs; this.logService=ls;
    }

    public Map<String, Object> generateQuiz(String userId, QuizGenerateRequest req) {
        User user = userRepo.findById(userId)
                .orElseThrow(() -> new RuntimeException("User không tồn tại."));

        if (req.getTopic() == null || req.getTopic().trim().isEmpty()) {
            throw new RuntimeException("Vui lòng nhập chủ đề.");
        }

        String types = req.getQuestionTypes() != null
                ? String.join(", ", req.getQuestionTypes())
                : "multiple_choice, short_answer, fill_in_blank";

        String raw;
        try {
            String level = user.getEducationLevel() != null ? user.getEducationLevel() : "high_school";
            raw = gemini.generate(gemini.buildQuizSystemPrompt(level),
                    "Tạo " + req.getNumQuestions() + " câu hỏi luyện tập về: \"" + req.getTopic().trim() + "\".\nCác dạng: " + types + ".");
        } catch (Exception e) {
            String msg = e.getMessage() != null ? e.getMessage() : "";
            if (msg.contains("429") || msg.contains("bận")) {
                throw new RuntimeException("AI đang bận, vui lòng thử lại sau 1 phút.");
            }
            throw new RuntimeException("Không tạo được quiz. Thử lại sau.");
        }

        String quizId = UUID.randomUUID().toString();
        Quiz quiz = new Quiz();
        quiz.setQuizId(quizId);
        quiz.setUserId(userId);
        try { quizRepo.save(quiz); } catch (Exception e) {
            log.error("Lỗi lưu quiz: {}", e.getMessage());
        }

        List<Map<String, Object>> questions = new ArrayList<>();
        try {
            JsonNode arr = mapper.readTree(raw).path("questions");
            if (arr.isArray()) {
                for (JsonNode item : arr) {
                    String qqId = UUID.randomUUID().toString();
                    QuizQuestion qq = new QuizQuestion();
                    qq.setQqId(qqId);
                    qq.setQuizId(quizId);
                    qq.setQuestionType(item.path("question_type").asText("short_answer"));
                    qq.setQuestionPayload(mapper.writeValueAsString(item));
                    try { qqRepo.save(qq); } catch (Exception ignored) {}

                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("qqId", qqId);
                    m.put("questionType", qq.getQuestionType());
                    m.put("question", item.path("question").asText(""));
                    if (item.has("options")) {
                        List<String> opts = new ArrayList<>();
                        item.path("options").forEach(o -> opts.add(o.asText()));
                        m.put("options", opts);
                    }
                    questions.add(m);
                }
            }
        } catch (Exception e) {
            log.error("Quiz parse error: {}", e.getMessage());
        }

        if (questions.isEmpty()) {
            throw new RuntimeException("AI không tạo được câu hỏi. Thử chủ đề khác.");
        }

        try { logService.logActivity(userId, "Generated_Quiz"); } catch (Exception ignored) {}

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("quizId", quizId);
        result.put("questions", questions);
        return result;
    }

    public Map<String, Object> gradeAnswer(String userId, String qqId, String userAnswer) {
        if (qqId == null || qqId.isBlank()) {
            throw new RuntimeException("Thiếu ID câu hỏi.");
        }
        if (userAnswer == null || userAnswer.trim().isEmpty()) {
            throw new RuntimeException("Vui lòng nhập câu trả lời.");
        }

        QuizQuestion qq = qqRepo.findById(qqId)
                .orElseThrow(() -> new RuntimeException("Câu hỏi không tồn tại."));

        try {
            JsonNode p = mapper.readTree(qq.getQuestionPayload());
            String correct = p.path("correct_answer").asText("");
            String expl = p.path("explanation").asText("");

            boolean ok = userAnswer.trim().equalsIgnoreCase(correct.trim());
            String fb = ok
                    ? "Chính xác! " + expl
                    : "Chưa đúng. Đáp án đúng là: " + correct + ". " + expl;

            qq.setUserAnswer(userAnswer);
            qq.setIsCorrect(ok);
            qq.setInstantFeedback(fb);
            try { qqRepo.save(qq); } catch (Exception ignored) {}

            if (ok) {
                try {
                    User u = userRepo.findById(userId).orElse(null);
                    if (u != null) {
                        u.setXpPoints((u.getXpPoints() != null ? u.getXpPoints() : 0) + 5);
                        userRepo.save(u);
                    }
                } catch (Exception ignored) {}
            }

            Map<String, Object> result = new LinkedHashMap<>();
            result.put("isCorrect", ok);
            result.put("instantFeedback", fb);
            return result;
        } catch (Exception e) {
            throw new RuntimeException("Lỗi chấm điểm. Thử lại.");
        }
    }
}
