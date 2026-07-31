package com.mentor.backend.repository;

import com.mentor.backend.entity.QuizQuestion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface QuizQuestionRepository extends JpaRepository<QuizQuestion, String> {
    // Lấy danh sách các câu hỏi thuộc về một bài Quiz cụ thể
    List<QuizQuestion> findByQuiz_QuizId(String quizId);

    // Kiểm tra xem câu hỏi này đã có trong Quiz chưa để tránh add trùng
    boolean existsByQuiz_QuizIdAndQuestion_QuestionId(String quizId, String questionId);
}