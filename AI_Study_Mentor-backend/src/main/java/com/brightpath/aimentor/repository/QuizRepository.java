package com.brightpath.aimentor.repository;

import com.brightpath.aimentor.entity.Quiz;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface QuizRepository extends JpaRepository<Quiz, String> {
    List<Quiz> findByUserIdOrderByCompletedAtDesc(String userId);
}
