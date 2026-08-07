package com.brightpath.aimentor.entity;
import jakarta.persistence.*;
import java.io.Serializable;
import java.time.LocalDateTime;

@Entity @Table(name = "user_achievements")
@IdClass(UserAchievement.PK.class)
public class UserAchievement {
    @Id @Column(length = 36) private String userId;
    @Id private Integer badgeId;
    private LocalDateTime unlockedAt = LocalDateTime.now();
    public UserAchievement() {}
    public String getUserId() { return userId; }
    public Integer getBadgeId() { return badgeId; }

    public static class PK implements Serializable {
        private String userId; private Integer badgeId;
        public PK() {}
        public PK(String u, Integer b) { userId = u; badgeId = b; }
        public int hashCode() { return (userId + badgeId).hashCode(); }
        public boolean equals(Object o) { return o instanceof PK p && userId.equals(p.userId) && badgeId.equals(p.badgeId); }
    }
}
