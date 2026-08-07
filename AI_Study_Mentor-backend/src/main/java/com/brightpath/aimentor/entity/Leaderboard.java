package com.brightpath.aimentor.entity;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity @Table(name = "leaderboard")
public class Leaderboard {
    @Id @Column(length = 36) private String leaderboardId;
    @Column(length = 36, nullable = false, unique = true) private String userId;
    @Column(name = "ranking") private Integer ranking;
    private Integer totalXpPoints;
    private LocalDateTime updatedAt = LocalDateTime.now();
    public Leaderboard() {}
    public Leaderboard(String id, String userId, Integer rank, Integer xp) {
        this.leaderboardId = id; this.userId = userId; this.ranking = rank; this.totalXpPoints = xp;
    }
    public String getLeaderboardId() { return leaderboardId; } public void setLeaderboardId(String v) { leaderboardId = v; }
    public String getUserId() { return userId; } public void setUserId(String v) { userId = v; }
    public Integer getRanking() { return ranking; }
    public Integer getTotalXpPoints() { return totalXpPoints; }
}
