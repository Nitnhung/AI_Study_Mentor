package com.brightpath.aimentor.service;

import com.brightpath.aimentor.entity.ActivityLog;
import com.brightpath.aimentor.repository.ActivityLogRepository;
import org.springframework.stereotype.Service;

@Service
public class ActivityLogService {
    private final ActivityLogRepository repo;
    public ActivityLogService(ActivityLogRepository repo) { this.repo = repo; }
    public void logActivity(String userId, String type) { repo.save(new ActivityLog(userId, type)); }
}
