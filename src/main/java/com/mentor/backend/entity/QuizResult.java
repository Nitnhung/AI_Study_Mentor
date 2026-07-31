package com.mentor.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "quiz_results")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class QuizResult {

    @Id
    @Column(name = "id", updatable = false, nullable = false)
    private String id;

    @Column(name = "quiz_id")
    private String quizId;

    private double score;
    private int correctAnswers;
    private int totalQuestions;

    @Column(name = "submitted_at")
    private LocalDateTime submittedAt;
}