package com.mentor.backend.controller;

import com.mentor.backend.dto.UserDTO;
import com.mentor.backend.entity.User;
import com.mentor.backend.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
// Đã xóa import UUID

@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*") // Rất quan trọng: Cho phép Flutter/Web gọi API mà không bị chặn lỗi CORS
public class UserController {

    @Autowired
    private UserService userService;

    // API Lấy danh sách Users (Phương thức GET)
    // URL: http://localhost:8080/api/users
    @GetMapping
    public ResponseEntity<List<UserDTO>> getAllUsers() {
        return ResponseEntity.ok(userService.getAllUsers());
    }

    // API Tạo User mới (Phương thức POST)
    // URL: http://localhost:8080/api/users
    @PostMapping
    public ResponseEntity<UserDTO> createUser(@RequestBody User user) {
        return ResponseEntity.ok(userService.createUser(user));
    }

    // API Lấy chi tiết 1 user theo ID
    @GetMapping("/{id}")
    public ResponseEntity<UserDTO> getUserById(@PathVariable String id) { // Sửa thành String
        return ResponseEntity.ok(userService.getUserById(id));
    }

    // API Cập nhật user
    @PutMapping("/{id}")
    public ResponseEntity<UserDTO> updateUser(@PathVariable String id, @RequestBody UserDTO userDTO) { // Sửa thành String
        // Đổi ResponseEntity<User> thành ResponseEntity<UserDTO>
        return ResponseEntity.ok(userService.updateUser(id, userDTO));
    }

    // API Xóa user (Vô hiệu hóa)
    @DeleteMapping("/{id}")
    public ResponseEntity<String> deleteUser(@PathVariable String id) { // Sửa thành String
        userService.deleteUser(id);
        return ResponseEntity.ok("Đã vô hiệu hóa user thành công!");
    }
}