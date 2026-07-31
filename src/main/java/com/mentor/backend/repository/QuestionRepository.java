package com.mentor.backend.repository;

import com.mentor.backend.entity.Question;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;
// Đã xóa import java.util.UUID;

@Repository
public interface QuestionRepository extends JpaRepository<Question, String> {

    // Tìm tất cả câu hỏi thuộc về một bài test (Quiz)
    @Query("SELECT qq.question FROM QuizQuestion qq WHERE qq.quiz.quizId = :quizId")
    List<Question> findQuestionsByQuizId(@Param("quizId") String quizId);

    // Tìm tất cả câu hỏi thuộc về một môn học (Subject)
    List<Question> findBySubject_SubjectId(String subjectId);
}