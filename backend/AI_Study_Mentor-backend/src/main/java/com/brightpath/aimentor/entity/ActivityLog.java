package com.brightpath.aimentor.entity;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity @Table(name = "activity_logs")
public class ActivityLog {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long logId;
    @Column(length = 36, nullable = false) private String userId;
    @Column(length = 50) private String activityType;
    private Integer timeSpentSeconds;
    private LocalDateTime createdAt = LocalDateTime.now();
    public ActivityLog() {}
    public ActivityLog(String userId, String type) { this.userId = userId; this.activityType = type; }
    public Long getLogId() { return logId; }
    public String getUserId() { return userId; } public void setUserId(String v) { userId = v; }
    public String getActivityType() { return activityType; } public void setActivityType(String v) { activityType = v; }
    public Integer getTimeSpentSeconds() { return timeSpentSeconds; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}
