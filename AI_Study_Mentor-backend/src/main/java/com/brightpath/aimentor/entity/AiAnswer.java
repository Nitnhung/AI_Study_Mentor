package com.brightpath.aimentor.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity @Table(name = "ai_answers")
public class AiAnswer {
    @Id @Column(length = 36) private String answerId;
    @Column(length = 36, nullable = false, unique = true) private String questionId;
    @Column(columnDefinition = "TEXT", nullable = false) private String contentData;
    private Boolean isCachedResponse = false;
    private Integer apiTokensUsed = 0;
    @Column(length = 50) private String aiModelVersion;
    private LocalDateTime createdAt = LocalDateTime.now();

    public AiAnswer() {}

    public String getAnswerId() { return answerId; } public void setAnswerId(String v) { answerId = v; }
    public String getQuestionId() { return questionId; } public void setQuestionId(String v) { questionId = v; }
    public String getContentData() { return contentData; } public void setContentData(String v) { contentData = v; }
    public Boolean getIsCachedResponse() { return isCachedResponse; } public void setIsCachedResponse(Boolean v) { isCachedResponse = v; }
    public Integer getApiTokensUsed() { return apiTokensUsed; } public void setApiTokensUsed(Integer v) { apiTokensUsed = v; }
    public String getAiModelVersion() { return aiModelVersion; } public void setAiModelVersion(String v) { aiModelVersion = v; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}
