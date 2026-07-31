package com.mentor.backend.controller;

import com.mentor.backend.dto.QuizQuestionDTO;
import com.mentor.backend.service.QuizQuestionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
// Đã xóa import UUID

@RestController
@RequestMapping("/api/quiz-questions")
public class QuizQuestionController {

    @Autowired
    private QuizQuestionService quizQuestionService;

    // API thêm câu hỏi vào Quiz
    @PostMapping
    public ResponseEntity<QuizQuestionDTO> addQuestionToQuiz(@RequestBody QuizQuestionDTO dto) {
        QuizQuestionDTO savedQuizQuestion = quizQuestionService.addQuestionToQuiz(dto);
        return new ResponseEntity<>(savedQuizQuestion, HttpStatus.CREATED);
    }

    // API lấy toàn bộ câu hỏi của 1 Quiz cụ thể (Rất quan trọng cho Flutter hiển thị bài test)
    @GetMapping("/quiz/{quizId}")
    public ResponseEntity<List<QuizQuestionDTO>> getQuestionsByQuizId(@PathVariable String quizId) { // Sửa thành String
        List<QuizQuestionDTO> questions = quizQuestionService.getQuestionsByQuizId(quizId);
        return ResponseEntity.ok(questions);
    }

    // API gỡ câu hỏi khỏi Quiz
    @DeleteMapping("/{id}")
    public ResponseEntity<String> removeQuestionFromQuiz(@PathVariable String id) {
        quizQuestionService.removeQuestionFromQuiz(id);
        return ResponseEntity.ok("Đã xóa câu hỏi khỏi Quiz thành công!");
    }
}