package com.brightpath.aimentor.controller;
import com.brightpath.aimentor.dto.*;
import com.brightpath.aimentor.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

@RestController @RequestMapping("/api/auth")
public class AuthController {
    private final AuthService authService;
    public AuthController(AuthService authService) { this.authService = authService; }
    @PostMapping("/register") public ApiResponse<AuthResponse> register(@Valid @RequestBody AuthRequest req) { return ApiResponse.ok("Đăng ký thành công", authService.register(req)); }
    @PostMapping("/login") public ApiResponse<AuthResponse> login(@Valid @RequestBody AuthRequest req) { return ApiResponse.ok("Đăng nhập thành công", authService.login(req)); }
}
