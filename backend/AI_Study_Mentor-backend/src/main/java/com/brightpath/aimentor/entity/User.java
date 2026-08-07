package com.brightpath.aimentor.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity @Table(name = "users")
public class User {
    @Id @Column(length = 36) private String userId;
    @Column(unique = true, nullable = false) private String email;
    @Column(nullable = false) private String passwordHash;
    @Column(length = 50) private String educationLevel;
    @Column(length = 50) private String preferredStyle;
    @Column(length = 50) private String subscriptionPlan;
    private Integer xpPoints = 0;
    private Boolean isActive = true;
    private LocalDateTime createdAt = LocalDateTime.now();
    private LocalDateTime updatedAt = LocalDateTime.now();

    public User() {}
    public User(String userId, String email, String passwordHash, String educationLevel,
                String preferredStyle, String subscriptionPlan, Integer xpPoints) {
        this.userId = userId; this.email = email; this.passwordHash = passwordHash;
        this.educationLevel = educationLevel; this.preferredStyle = preferredStyle;
        this.subscriptionPlan = subscriptionPlan; this.xpPoints = xpPoints;
    }

    @PreUpdate void onUpdate() { this.updatedAt = LocalDateTime.now(); }

    public String getUserId() { return userId; }
    public void setUserId(String v) { userId = v; }
    public String getEmail() { return email; }
    public void setEmail(String v) { email = v; }
    public String getPasswordHash() { return passwordHash; }
    public void setPasswordHash(String v) { passwordHash = v; }
    public String getEducationLevel() { return educationLevel; }
    public void setEducationLevel(String v) { educationLevel = v; }
    public String getPreferredStyle() { return preferredStyle; }
    public void setPreferredStyle(String v) { preferredStyle = v; }
    public String getSubscriptionPlan() { return subscriptionPlan; }
    public void setSubscriptionPlan(String v) { subscriptionPlan = v; }
    public Integer getXpPoints() { return xpPoints; }
    public void setXpPoints(Integer v) { xpPoints = v; }
    public Boolean getIsActive() { return isActive; }
    public void setIsActive(Boolean v) { isActive = v; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime v) { createdAt = v; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
