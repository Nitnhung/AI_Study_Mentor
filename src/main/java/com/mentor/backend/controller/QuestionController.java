package com.mentor.backend.controller;

import com.mentor.backend.dto.QuestionDTO;
import com.mentor.backend.service.QuestionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/questions")
@CrossOrigin(origins = "*") // Hỗ trợ gọi API từ Flutter/Frontend mà không bị lỗi CORS
public class QuestionController {

    @Autowired
    private QuestionService questionService;

    // 1. CREATE: Tạo câu hỏi mới
    // POST: http://localhost:8080/api/questions
    @PostMapping
    public ResponseEntity<QuestionDTO> createQuestion(@RequestBody QuestionDTO questionDTO) {
        QuestionDTO createdQuestion = questionService.createQuestion(questionDTO);
        return ResponseEntity.status(HttpStatus.CREATED).body(createdQuestion);
    }

    // 2. READ: Lấy danh sách tất cả câu hỏi
    // GET: http://localhost:8080/api/questions
    @GetMapping
    public ResponseEntity<List<QuestionDTO>> getAllQuestions() {
        List<QuestionDTO> questions = questionService.getAllQuestions();
        return ResponseEntity.ok(questions);
    }

    // 3. READ: Lấy chi tiết một câu hỏi theo ID
    // GET: http://localhost:8080/api/questions/{id}
    @GetMapping("/{id}")
    public ResponseEntity<QuestionDTO> getQuestionById(@PathVariable String id) {
        QuestionDTO question = questionService.getQuestionById(id);
        return ResponseEntity.ok(question);
    }

    // 4. UPDATE: Cập nhật thông tin câu hỏi
    // PUT: http://localhost:8080/api/questions/{id}
    @PutMapping("/{id}")
    public ResponseEntity<QuestionDTO> updateQuestion(@PathVariable String id, @RequestBody QuestionDTO questionDTO) {
        QuestionDTO updatedQuestion = questionService.updateQuestion(id, questionDTO);
        return ResponseEntity.ok(updatedQuestion);
    }

    // 5. DELETE: Xóa câu hỏi
    // DELETE: http://localhost:8080/api/questions/{id}
    @DeleteMapping("/{id}")
    public ResponseEntity<String> deleteQuestion(@PathVariable String id) {
        questionService.deleteQuestion(id);
        return ResponseEntity.ok("Đã xóa câu hỏi thành công!");
    }

    // 6. READ: Lấy danh sách câu hỏi theo Subject ID
    // GET: http://localhost:8080/api/questions/subject/{subjectId}
    @GetMapping("/subject/{subjectId}")
    public ResponseEntity<List<QuestionDTO>> getQuestionsBySubjectId(@PathVariable String subjectId) {
        List<QuestionDTO> questions = questionService.getQuestionsBySubjectId(subjectId);
        return ResponseEntity.ok(questions);
    }
}