package com.brightpath.aimentor.dto;
import java.util.List;

public class AiAnswerResponse {
    private String questionId, subject, difficulty, directAnswer, explanation, simplifiedExplanation, model;
    private List<String> steps, formulasOrConcepts, alternativeApproaches, keyConceptsSummary, commonMistakes, followUpQuestions;
    private boolean cachedResponse; private int tokensUsed;
    public AiAnswerResponse() {}

    public String getQuestionId() { return questionId; } public void setQuestionId(String v) { questionId = v; }
    public String getSubject() { return subject; } public void setSubject(String v) { subject = v; }
    public String getDifficulty() { return difficulty; } public void setDifficulty(String v) { difficulty = v; }
    public String getDirectAnswer() { return directAnswer; } public void setDirectAnswer(String v) { directAnswer = v; }
    public String getExplanation() { return explanation; } public void setExplanation(String v) { explanation = v; }
    public List<String> getSteps() { return steps; } public void setSteps(List<String> v) { steps = v; }
    public List<String> getFormulasOrConcepts() { return formulasOrConcepts; } public void setFormulasOrConcepts(List<String> v) { formulasOrConcepts = v; }
    public String getSimplifiedExplanation() { return simplifiedExplanation; } public void setSimplifiedExplanation(String v) { simplifiedExplanation = v; }
    public List<String> getAlternativeApproaches() { return alternativeApproaches; } public void setAlternativeApproaches(List<String> v) { alternativeApproaches = v; }
    public List<String> getKeyConceptsSummary() { return keyConceptsSummary; } public void setKeyConceptsSummary(List<String> v) { keyConceptsSummary = v; }
    public List<String> getCommonMistakes() { return commonMistakes; } public void setCommonMistakes(List<String> v) { commonMistakes = v; }
    public List<String> getFollowUpQuestions() { return followUpQuestions; } public void setFollowUpQuestions(List<String> v) { followUpQuestions = v; }
    public boolean isCachedResponse() { return cachedResponse; } public void setCachedResponse(boolean v) { cachedResponse = v; }
    public int getTokensUsed() { return tokensUsed; } public void setTokensUsed(int v) { tokensUsed = v; }
    public String getModel() { return model; } public void setModel(String v) { model = v; }
}
