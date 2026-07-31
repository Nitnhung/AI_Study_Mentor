package com.mentor.backend.repository;

import com.mentor.backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

// Đã xóa import java.util.UUID;

@Repository
public interface UserRepository extends JpaRepository<User, String> { // Đã sửa UUID thành String
    // Không cần viết thêm gì ở đây, Spring Data JPA đã tự động lo hết các hàm CRUD cơ bản như findById, save, delete...
}