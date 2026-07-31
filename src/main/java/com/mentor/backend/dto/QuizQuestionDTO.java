package com.mentor.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class QuizQuestionDTO {
    private String id;
    private String quizId;
    private String questionId;
    private Boolean isCorrect;
}