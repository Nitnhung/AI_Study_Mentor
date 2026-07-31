package com.mentor.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class QuestionDTO {
    private String questionId;
    private String userId;
    private String subjectId;
    private String questionText;
    private String imageUrl;

    // THÊM MỚI: Các biến này sẽ tạo thành key JSON để Flutter đọc
    private String optionA;
    private String optionB;
    private String optionC;
    private String optionD;
    private String correctAnswer;

    private LocalDateTime createdAt;
}