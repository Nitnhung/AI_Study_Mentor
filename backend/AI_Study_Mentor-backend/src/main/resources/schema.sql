-- ══════════════════════════════════════════════════════════
-- AI STUDY MENTOR — DATABASE (MySQL / XAMPP)
-- Chạy file này trong phpMyAdmin hoặc MySQL Workbench
-- TRƯỚC KHI chạy backend Spring Boot
-- ══════════════════════════════════════════════════════════

DROP DATABASE IF EXISTS mentor_db;
CREATE DATABASE mentor_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE mentor_db;

-- ═══════════════════════════════════════════
-- BẢNG
-- ═══════════════════════════════════════════

CREATE TABLE users (
    user_id CHAR(36) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    education_level VARCHAR(50) DEFAULT 'high_school',
    preferred_style VARCHAR(50) DEFAULT 'step_by_step',
    subscription_plan VARCHAR(50) DEFAULT 'free',
    xp_points INT DEFAULT 0,
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE subjects (
    subject_id CHAR(36) PRIMARY KEY,
    subject_name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT
) ENGINE=InnoDB;

CREATE TABLE questions (
    question_id CHAR(36) PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    subject_id CHAR(36),
    question_text TEXT NOT NULL,
    image_url VARCHAR(255),
    extracted_text_from_image TEXT,
    question_hash VARCHAR(255),
    status VARCHAR(20) DEFAULT 'Pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (subject_id) REFERENCES subjects(subject_id) ON DELETE SET NULL,
    INDEX idx_question_hash (question_hash),
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB;

CREATE TABLE ai_answers (
    answer_id CHAR(36) PRIMARY KEY,
    question_id CHAR(36) NOT NULL UNIQUE,
    content_data JSON NOT NULL,
    is_cached_response TINYINT(1) DEFAULT 0,
    api_tokens_used INT DEFAULT 0,
    ai_model_version VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (question_id) REFERENCES questions(question_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE bookmarks (
    bookmark_id CHAR(36) PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    question_id CHAR(36) NOT NULL,
    folder_name VARCHAR(100) DEFAULT 'Mặc định',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES questions(question_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE quizzes (
    quiz_id CHAR(36) PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    subject_id CHAR(36),
    base_question_id CHAR(36),
    score_percentage DECIMAL(5,2),
    completed_at TIMESTAMP NULL DEFAULT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (subject_id) REFERENCES subjects(subject_id) ON DELETE SET NULL,
    FOREIGN KEY (base_question_id) REFERENCES questions(question_id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE quiz_questions (
    qq_id CHAR(36) PRIMARY KEY,
    quiz_id CHAR(36) NOT NULL,
    question_type VARCHAR(50),
    question_payload JSON NOT NULL,
    user_answer TEXT,
    is_correct TINYINT(1),
    instant_feedback TEXT,
    FOREIGN KEY (quiz_id) REFERENCES quizzes(quiz_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE activity_logs (
    log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    activity_type VARCHAR(50),
    time_spent_seconds INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE user_achievements (
    user_id CHAR(36) NOT NULL,
    badge_id INT NOT NULL,
    unlocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, badge_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE notifications (
    notification_id CHAR(36) PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50),
    is_read TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE leaderboard (
    leaderboard_id CHAR(36) PRIMARY KEY,
    user_id CHAR(36) NOT NULL UNIQUE,
    ranking INT,
    total_xp_points INT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ═══════════════════════════════════════════
-- DỮ LIỆU MẪU (Thầy mở DB phải thấy dữ liệu)
-- ═══════════════════════════════════════════

-- Môn học
INSERT INTO subjects VALUES
('s-math', 'Toán', 'Toán học từ cơ bản đến nâng cao'),
('s-eng',  'Tiếng Anh', 'Ngữ pháp, từ vựng, kỹ năng nghe nói đọc viết'),
('s-phys', 'Vật Lý', 'Cơ học, nhiệt học, điện từ, quang học'),
('s-chem', 'Hoá Học', 'Hoá vô cơ, hoá hữu cơ'),
('s-it',   'CNTT', 'Lập trình, mạng máy tính, cơ sở dữ liệu'),
('s-hist', 'Lịch Sử', 'Lịch sử Việt Nam và thế giới');

-- Users (password: 123456 → BCrypt hash)
-- Users được tạo tự động bởi DataSeeder khi backend khởi động lần đầu
-- (đảm bảo BCrypt hash chính xác với password thật)

-- Dữ liệu mẫu (users, questions, answers, notifications, leaderboard...)
-- được tạo TỰ ĐỘNG bởi DataSeeder.java khi backend khởi động lần đầu.
-- Khi người dùng đăng ký/hỏi AI/làm quiz → dữ liệu mới thêm vào các bảng trên.
