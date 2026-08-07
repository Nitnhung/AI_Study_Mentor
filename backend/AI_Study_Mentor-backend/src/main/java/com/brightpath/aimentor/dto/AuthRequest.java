package com.brightpath.aimentor.dto;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public class AuthRequest {
    @Email @NotBlank private String email;
    @NotBlank private String password;
    private String fullName;
    public String getEmail() { return email; } public void setEmail(String v) { email = v; }
    public String getPassword() { return password; } public void setPassword(String v) { password = v; }
    public String getFullName() { return fullName; } public void setFullName(String v) { fullName = v; }
}
