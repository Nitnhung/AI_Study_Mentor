package com.brightpath.aimentor.entity;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity @Table(name = "notifications")
public class Notification {
    @Id @Column(length = 36) private String notificationId;
    @Column(length = 36, nullable = false) private String userId;
    @Column(columnDefinition = "TEXT", nullable = false) private String message;
    @Column(length = 50) private String type;
    private Boolean isRead = false;
    private LocalDateTime createdAt = LocalDateTime.now();
    public Notification() {}
    public Notification(String id, String userId, String msg, String type) {
        this.notificationId = id; this.userId = userId; this.message = msg; this.type = type;
    }
    public String getNotificationId() { return notificationId; } public void setNotificationId(String v) { notificationId = v; }
    public String getUserId() { return userId; } public void setUserId(String v) { userId = v; }
    public String getMessage() { return message; } public void setMessage(String v) { message = v; }
    public String getType() { return type; } public void setType(String v) { type = v; }
    public Boolean getIsRead() { return isRead; } public void setIsRead(Boolean v) { isRead = v; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}
