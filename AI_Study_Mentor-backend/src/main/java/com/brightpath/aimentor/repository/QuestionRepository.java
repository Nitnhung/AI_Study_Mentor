package com.brightpath.aimentor.repository;

import com.brightpath.aimentor.entity.Question;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface QuestionRepository extends JpaRepository<Question, String> {
    List<Question> findByUserIdOrderByCreatedAtDesc(String userId);
    List<Question> findByQuestionHashOrderByCreatedAtDesc(String hash);
}
