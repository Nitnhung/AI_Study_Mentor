package com.mentor.backend.service;

import com.mentor.backend.entity.QuizResult;
import com.mentor.backend.repository.QuizResultRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

@Service
public class QuizResultService {

    @Autowired
    private QuizResultRepository quizResultRepository;

    public QuizResult saveResult(String quizId, double score, int correctAnswers, int totalQuestions) {
        QuizResult result = new QuizResult();
        result.setId(java.util.UUID.randomUUID().toString());
        result.setQuizId(quizId);
        result.setScore(score);
        result.setCorrectAnswers(correctAnswers);
        result.setTotalQuestions(totalQuestions);
        result.setSubmittedAt(LocalDateTime.now());

        // (Sau này bạn có thể bổ sung thêm việc lưu userId vào đây)

        return quizResultRepository.save(result);
    }
}