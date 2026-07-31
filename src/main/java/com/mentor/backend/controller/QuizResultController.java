package com.mentor.backend.controller;

import com.mentor.backend.entity.QuizResult;
import com.mentor.backend.service.QuizResultService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/results") // Khớp với đường dẫn API mà Frontend đang gọi
@CrossOrigin(origins = "*") // Tránh lỗi CORS khi gọi từ thiết bị khác
public class QuizResultController {

    @Autowired
    private QuizResultService quizResultService;

    @PostMapping
    public ResponseEntity<?> submitQuizResult(@RequestBody Map<String, Object> payload) {
        try {
            // Trích xuất dữ liệu từ JSON mà Frontend gửi lên
            String quizId = payload.get("quizId").toString();
            double score = Double.parseDouble(payload.get("score").toString());
            int correctAnswers = Integer.parseInt(payload.get("correctAnswers").toString());
            int totalQuestions = Integer.parseInt(payload.get("totalQuestions").toString());

            QuizResult savedResult = quizResultService.saveResult(quizId, score, correctAnswers, totalQuestions);

            return ResponseEntity.ok(savedResult);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Lỗi khi lưu kết quả: " + e.getMessage());
        }
    }
}