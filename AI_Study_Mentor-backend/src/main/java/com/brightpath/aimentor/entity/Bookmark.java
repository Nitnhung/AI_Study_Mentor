package com.brightpath.aimentor.entity;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity @Table(name = "bookmarks")
public class Bookmark {
    @Id @Column(length = 36) private String bookmarkId;
    @Column(length = 36, nullable = false) private String userId;
    @Column(length = 36, nullable = false) private String questionId;
    @Column(length = 100) private String folderName;
    private LocalDateTime createdAt = LocalDateTime.now();
    public Bookmark() {}
    public String getBookmarkId() { return bookmarkId; } public void setBookmarkId(String v) { bookmarkId = v; }
    public String getUserId() { return userId; } public void setUserId(String v) { userId = v; }
    public String getQuestionId() { return questionId; } public void setQuestionId(String v) { questionId = v; }
    public String getFolderName() { return folderName; } public void setFolderName(String v) { folderName = v; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}
