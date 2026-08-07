package com.brightpath.aimentor.dto;
import java.util.List;

public class QuizGenerateRequest {
    private String topic; private int numQuestions = 5; private List<String> questionTypes;
    public String getTopic() { return topic; } public void setTopic(String v) { topic = v; }
    public int getNumQuestions() { return numQuestions; } public void setNumQuestions(int v) { numQuestions = v; }
    public List<String> getQuestionTypes() { return questionTypes; } public void setQuestionTypes(List<String> v) { questionTypes = v; }
}
