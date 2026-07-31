package com.mentor.backend.controller;

import com.mentor.backend.dto.QuizDTO;
import com.mentor.backend.entity.Question;
import com.mentor.backend.service.QuizService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

import java.util.List;
// Đã xóa import UUID

@RestController
@RequestMapping("/api/quizzes")
public class QuizController {

    @Autowired
    private QuizService quizService;

    // Tạo mới một bài thi (Quiz)
    @PostMapping
    public ResponseEntity<QuizDTO> createQuiz(@RequestBody QuizDTO quizDTO) {
        QuizDTO createdQuiz = quizService.createQuiz(quizDTO);
        return new ResponseEntity<>(createdQuiz, HttpStatus.CREATED);
    }

    // Lấy thông tin một bài thi theo ID
    @GetMapping("/{quizId}")
    public ResponseEntity<QuizDTO> getQuizById(@PathVariable String quizId) { // Sửa thành String
        QuizDTO quizDTO = quizService.getQuizById(quizId);
        return ResponseEntity.ok(quizDTO);
    }

    // Lấy danh sách toàn bộ bài thi
    @GetMapping
    public ResponseEntity<List<QuizDTO>> getAllQuizzes() {
        List<QuizDTO> quizzes = quizService.getAllQuizzes();
        return ResponseEntity.ok(quizzes);
    }

    // Lấy danh sách bài thi theo môn học (Subject ID)
    @GetMapping("/subject/{subjectId}")
    public ResponseEntity<List<QuizDTO>> getQuizzesBySubjectId(@PathVariable String subjectId) { // Sửa thành String
        List<QuizDTO> quizzes = quizService.getQuizzesBySubjectId(subjectId);
        return ResponseEntity.ok(quizzes);
    }

    // Cập nhật thông tin bài thi
    @PutMapping("/{quizId}")
    public ResponseEntity<QuizDTO> updateQuiz(@PathVariable String quizId, @RequestBody QuizDTO quizDTO) { // Sửa thành String
        QuizDTO updatedQuiz = quizService.updateQuiz(quizId, quizDTO);
        return ResponseEntity.ok(updatedQuiz);
    }

    // Xóa bài thi
    @DeleteMapping("/{quizId}")
    public ResponseEntity<String> deleteQuiz(@PathVariable String quizId) { // Sửa thành String
        quizService.deleteQuiz(quizId);
        return ResponseEntity.ok("Đã xóa thành công Quiz với ID: " + quizId);
    }

    @GetMapping("/{quizId}/questions")
    public ResponseEntity<List<com.mentor.backend.dto.QuestionDTO>> getQuizQuestions(@PathVariable String quizId) { // Sửa thành String
        try {
            // Sửa List<Question> thành List<QuestionDTO>
            List<com.mentor.backend.dto.QuestionDTO> questions = quizService.getQuestionsByQuiz(quizId);
            return ResponseEntity.ok(questions);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        }
    }
}