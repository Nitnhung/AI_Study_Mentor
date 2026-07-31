package com.mentor.backend.service;

import com.mentor.backend.dto.QuizDTO;
import com.mentor.backend.entity.Question;

import java.util.List;
// Đã xóa import UUID

public interface QuizService {
    QuizDTO createQuiz(QuizDTO quizDTO);
    QuizDTO getQuizById(String quizId); // Sửa thành String
    List<QuizDTO> getAllQuizzes();
    List<QuizDTO> getQuizzesBySubjectId(String subjectId); // Sửa thành String
    List<com.mentor.backend.dto.QuestionDTO> getQuestionsByQuiz(String quizId); // Sửa thành String
    QuizDTO updateQuiz(String quizId, QuizDTO quizDTO); // Sửa thành String
    void deleteQuiz(String quizId); // Sửa thành String
}