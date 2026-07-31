package com.mentor.backend.service;

import com.mentor.backend.dto.QuizQuestionDTO;

import java.util.List;
// Đã xóa import UUID

public interface QuizQuestionService {
    QuizQuestionDTO addQuestionToQuiz(QuizQuestionDTO dto);
    List<QuizQuestionDTO> getQuestionsByQuizId(String quizId); // Sửa thành String
    void removeQuestionFromQuiz(String id);
}