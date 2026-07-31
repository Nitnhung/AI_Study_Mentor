package com.mentor.backend.service;

import com.mentor.backend.dto.UserDTO;
import com.mentor.backend.entity.User;
import com.mentor.backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;

    // Hàm phụ trợ: Chuyển đổi từ Entity (Database) sang DTO (Trả về Frontend)
    private UserDTO mapToDTO(User user) {
        return UserDTO.builder()
                .userId(user.getUserId())
                .username(user.getUsername())
                .email(user.getEmail())
                .educationLevel(user.getEducationLevel())
                .preferredStyle(user.getPreferredStyle())
                .isActive(user.getIsActive())
                .build();
    }

    // Lấy danh sách toàn bộ User
    public List<UserDTO> getAllUsers() {
        List<User> users = userRepository.findAll();
        return users.stream().map(this::mapToDTO).collect(Collectors.toList());
    }

    // Tạo User mới (Test đơn giản, mật khẩu đang để thô, sau này sẽ mã hóa sau)
    public UserDTO createUser(User user) {
        user.setUserId(UUID.randomUUID().toString());
        User savedUser = userRepository.save(user);
        return mapToDTO(savedUser);
    }

    // Lấy 1 user cụ thể theo ID
    public UserDTO getUserById(String id) { // Sửa thành String
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy user với ID: " + id));
        return mapToDTO(user);
    }

    // Cập nhật thông tin user
    public UserDTO updateUser(String id, UserDTO userDTO) { // Sửa thành String
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy user với ID: " + id));

        user.setEducationLevel(userDTO.getEducationLevel());
        user.setPreferredStyle(userDTO.getPreferredStyle());

        // Sử dụng hàm mapToDTO đã viết sẵn ở trên để trả về dữ liệu an toàn
        return mapToDTO(userRepository.save(user));
    }

    // Xóa user (Soft Delete)
    public void deleteUser(String id) { // Sửa thành String
        User existingUser = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy user với ID: " + id));

        // Thay vì xóa hẳn, ta chỉ tắt trạng thái hoạt động
        existingUser.setIsActive(false);
        userRepository.save(existingUser);
    }
}