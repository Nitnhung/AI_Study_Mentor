package com.brightpath.aimentor.entity;

import jakarta.persistence.*;

@Entity @Table(name = "quiz_questions")
public class QuizQuestion {
    @Id @Column(length = 36) private String qqId;
    @Column(length = 36, nullable = false) private String quizId;
    @Column(length = 50) private String questionType;
    @Column(columnDefinition = "TEXT", nullable = false) private String questionPayload;
    @Column(columnDefinition = "TEXT") private String userAnswer;
    private Boolean isCorrect;
    @Column(columnDefinition = "TEXT") private String instantFeedback;

    public QuizQuestion() {}

    public String getQqId() { return qqId; } public void setQqId(String v) { qqId = v; }
    public String getQuizId() { return quizId; } public void setQuizId(String v) { quizId = v; }
    public String getQuestionType() { return questionType; } public void setQuestionType(String v) { questionType = v; }
    public String getQuestionPayload() { return questionPayload; } public void setQuestionPayload(String v) { questionPayload = v; }
    public String getUserAnswer() { return userAnswer; } public void setUserAnswer(String v) { userAnswer = v; }
    public Boolean getIsCorrect() { return isCorrect; } public void setIsCorrect(Boolean v) { isCorrect = v; }
    public String getInstantFeedback() { return instantFeedback; } public void setInstantFeedback(String v) { instantFeedback = v; }
}
