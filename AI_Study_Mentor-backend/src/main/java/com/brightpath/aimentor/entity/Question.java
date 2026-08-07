package com.brightpath.aimentor.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity @Table(name = "questions")
public class Question {
    @Id @Column(length = 36) private String questionId;
    @Column(length = 36, nullable = false) private String userId;
    @Column(length = 36) private String subjectId;
    @Column(columnDefinition = "TEXT", nullable = false) private String questionText;
    private String imageUrl;
    @Column(columnDefinition = "TEXT") private String extractedTextFromImage;
    private String questionHash;
    @Column(length = 20) private String status = "Pending";
    private LocalDateTime createdAt = LocalDateTime.now();

    public Question() {}

    public String getQuestionId() { return questionId; } public void setQuestionId(String v) { questionId = v; }
    public String getUserId() { return userId; } public void setUserId(String v) { userId = v; }
    public String getSubjectId() { return subjectId; } public void setSubjectId(String v) { subjectId = v; }
    public String getQuestionText() { return questionText; } public void setQuestionText(String v) { questionText = v; }
    public String getImageUrl() { return imageUrl; } public void setImageUrl(String v) { imageUrl = v; }
    public String getExtractedTextFromImage() { return extractedTextFromImage; } public void setExtractedTextFromImage(String v) { extractedTextFromImage = v; }
    public String getQuestionHash() { return questionHash; } public void setQuestionHash(String v) { questionHash = v; }
    public String getStatus() { return status; } public void setStatus(String v) { status = v; }
    public LocalDateTime getCreatedAt() { return createdAt; } public void setCreatedAt(LocalDateTime v) { createdAt = v; }
}
