package com.mentor.backend.dto;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class SubjectDTO {
    private String subjectId;
    private String subjectName;
    private String description;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}