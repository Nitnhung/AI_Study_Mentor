package com.brightpath.aimentor.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity @Table(name = "quizzes")
public class Quiz {
    @Id @Column(length = 36) private String quizId;
    @Column(length = 36, nullable = false) private String userId;
    @Column(length = 36) private String subjectId;
    @Column(length = 36) private String baseQuestionId;
    @Column(precision = 5, scale = 2) private BigDecimal scorePercentage;
    private LocalDateTime completedAt;

    public Quiz() {}

    public String getQuizId() { return quizId; } public void setQuizId(String v) { quizId = v; }
    public String getUserId() { return userId; } public void setUserId(String v) { userId = v; }
    public String getSubjectId() { return subjectId; } public void setSubjectId(String v) { subjectId = v; }
    public String getBaseQuestionId() { return baseQuestionId; } public void setBaseQuestionId(String v) { baseQuestionId = v; }
    public BigDecimal getScorePercentage() { return scorePercentage; } public void setScorePercentage(BigDecimal v) { scorePercentage = v; }
    public LocalDateTime getCompletedAt() { return completedAt; } public void setCompletedAt(LocalDateTime v) { completedAt = v; }
}
