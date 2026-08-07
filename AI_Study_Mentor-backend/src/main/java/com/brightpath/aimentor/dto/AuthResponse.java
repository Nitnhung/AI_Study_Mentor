package com.brightpath.aimentor.dto;

public class AuthResponse {
    private String token, userId, email, educationLevel, preferredStyle;
    private Integer xpPoints;
    public AuthResponse() {}
    public AuthResponse(String token, String userId, String email, String el, String ps, Integer xp) {
        this.token=token; this.userId=userId; this.email=email; this.educationLevel=el; this.preferredStyle=ps; this.xpPoints=xp;
    }
    public String getToken() { return token; } public String getUserId() { return userId; }
    public String getEmail() { return email; } public String getEducationLevel() { return educationLevel; }
    public String getPreferredStyle() { return preferredStyle; } public Integer getXpPoints() { return xpPoints; }
}
