package com.brightpath.aimentor.controller;
import com.brightpath.aimentor.dto.ApiResponse;
import com.brightpath.aimentor.entity.User;
import com.brightpath.aimentor.repository.UserRepository;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.*;

@RestController @RequestMapping("/api/users")
public class UserController {
    private final UserRepository userRepo;
    public UserController(UserRepository userRepo) { this.userRepo = userRepo; }

    @GetMapping("/me") public ApiResponse<Map<String,Object>> me(Authentication auth) {
        User u = userRepo.findById(auth.getPrincipal().toString()).orElseThrow(() -> new RuntimeException("User không tồn tại."));
        Map<String,Object> m = new LinkedHashMap<>();
        m.put("userId",u.getUserId()); m.put("email",u.getEmail());
        m.put("educationLevel",u.getEducationLevel()!=null?u.getEducationLevel():"");
        m.put("preferredStyle",u.getPreferredStyle()!=null?u.getPreferredStyle():"");
        m.put("xpPoints",u.getXpPoints()); m.put("subscriptionPlan",u.getSubscriptionPlan()!=null?u.getSubscriptionPlan():"free");
        m.put("createdAt",u.getCreatedAt().toString());
        return ApiResponse.ok(m);
    }
    @PutMapping("/me") public ApiResponse<String> update(Authentication auth, @RequestBody Map<String,String> body) {
        User u = userRepo.findById(auth.getPrincipal().toString()).orElseThrow(() -> new RuntimeException("User không tồn tại."));
        if(body.containsKey("educationLevel")) u.setEducationLevel(body.get("educationLevel"));
        if(body.containsKey("preferredStyle")) u.setPreferredStyle(body.get("preferredStyle"));
        userRepo.save(u); return ApiResponse.ok("Cập nhật thành công", null);
    }
}
