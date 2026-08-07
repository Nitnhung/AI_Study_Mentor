package com.brightpath.aimentor.repository;

import com.brightpath.aimentor.entity.AiAnswer;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface AiAnswerRepository extends JpaRepository<AiAnswer, String> {
    Optional<AiAnswer> findByQuestionId(String questionId);
}
