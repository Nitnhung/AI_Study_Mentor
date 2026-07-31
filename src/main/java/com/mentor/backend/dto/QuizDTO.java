package com.mentor.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class QuizDTO {
    private String quizId;
    private String userId;
    private String subjectId;
    private String title;
    private String description;
    private Integer totalScore;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}