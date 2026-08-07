package com.brightpath.aimentor.controller;
import com.brightpath.aimentor.dto.ApiResponse;
import com.brightpath.aimentor.entity.Notification;
import com.brightpath.aimentor.repository.NotificationRepository;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.*;

@RestController @RequestMapping("/api/notifications")
public class NotificationController {
    private final NotificationRepository repo;
    public NotificationController(NotificationRepository repo) { this.repo = repo; }
    @GetMapping public ApiResponse<List<Notification>> list(Authentication a) { return ApiResponse.ok(repo.findByUserIdOrderByCreatedAtDesc(a.getPrincipal().toString())); }
    @PutMapping("/{id}/read") public ApiResponse<String> markRead(@PathVariable String id) { repo.findById(id).ifPresent(n -> { n.setIsRead(true); repo.save(n); }); return ApiResponse.ok("Đã đọc",null); }
}
