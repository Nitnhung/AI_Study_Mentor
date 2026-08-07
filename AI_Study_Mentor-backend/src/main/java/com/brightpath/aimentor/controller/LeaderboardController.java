package com.brightpath.aimentor.controller;
import com.brightpath.aimentor.dto.ApiResponse;
import com.brightpath.aimentor.entity.Leaderboard;
import com.brightpath.aimentor.repository.LeaderboardRepository;
import org.springframework.web.bind.annotation.*;
import java.util.*;

@RestController @RequestMapping("/api/leaderboard")
public class LeaderboardController {
    private final LeaderboardRepository repo;
    public LeaderboardController(LeaderboardRepository repo) { this.repo = repo; }
    @GetMapping public ApiResponse<List<Leaderboard>> list() { return ApiResponse.ok(repo.findAllByOrderByTotalXpPointsDesc()); }
}
