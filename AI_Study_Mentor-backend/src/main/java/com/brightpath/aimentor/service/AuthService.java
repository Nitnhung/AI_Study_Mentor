package com.brightpath.aimentor.service;

import com.brightpath.aimentor.dto.*;
import com.brightpath.aimentor.entity.User;
import com.brightpath.aimentor.repository.UserRepository;
import com.brightpath.aimentor.security.JwtUtil;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import java.util.UUID;

@Service
public class AuthService {
    private final UserRepository userRepo;
    private final PasswordEncoder encoder;
    private final JwtUtil jwtUtil;

    public AuthService(UserRepository userRepo, PasswordEncoder encoder, JwtUtil jwtUtil) {
        this.userRepo = userRepo; this.encoder = encoder; this.jwtUtil = jwtUtil;
    }

    public AuthResponse register(AuthRequest req) {
        if (req.getEmail() == null || req.getEmail().trim().isEmpty()) {
            throw new RuntimeException("Vui lòng nhập email.");
        }
        if (req.getPassword() == null || req.getPassword().isEmpty()) {
            throw new RuntimeException("Vui lòng nhập mật khẩu.");
        }
        if (req.getPassword().length() < 6) {
            throw new RuntimeException("Mật khẩu phải có ít nhất 6 ký tự.");
        }
        if (userRepo.existsByEmail(req.getEmail().trim())) {
            throw new RuntimeException("Email đã tồn tại.");
        }
        try {
            User user = new User(UUID.randomUUID().toString(), req.getEmail().trim(),
                    encoder.encode(req.getPassword()), "high_school", "step_by_step", "free", 0);
            userRepo.save(user);
            return toResponse(user, jwtUtil.generateToken(user.getUserId(), user.getEmail()));
        } catch (Exception e) {
            throw new RuntimeException("Đăng ký thất bại. Thử lại sau.");
        }
    }

    public AuthResponse login(AuthRequest req) {
        if (req.getEmail() == null || req.getEmail().trim().isEmpty()) {
            throw new RuntimeException("Vui lòng nhập email.");
        }
        if (req.getPassword() == null || req.getPassword().isEmpty()) {
            throw new RuntimeException("Vui lòng nhập mật khẩu.");
        }
        User user = userRepo.findByEmail(req.getEmail().trim())
                .orElseThrow(() -> new RuntimeException("Email không tồn tại."));
        if (!encoder.matches(req.getPassword(), user.getPasswordHash())) {
            throw new RuntimeException("Mật khẩu không đúng.");
        }
        return toResponse(user, jwtUtil.generateToken(user.getUserId(), user.getEmail()));
    }

    private AuthResponse toResponse(User u, String token) {
        return new AuthResponse(token, u.getUserId(), u.getEmail(),
                u.getEducationLevel(), u.getPreferredStyle(),
                u.getXpPoints() != null ? u.getXpPoints() : 0);
    }
}
