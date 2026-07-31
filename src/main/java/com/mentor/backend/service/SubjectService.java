package com.mentor.backend.service;

import com.mentor.backend.dto.SubjectDTO;
import com.mentor.backend.entity.Subject;
import com.mentor.backend.repository.SubjectRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class SubjectService {

    @Autowired
    private SubjectRepository subjectRepository;

    // Helper method: Map Entity sang DTO
    private SubjectDTO mapToDTO(Subject subject) {
        SubjectDTO dto = new SubjectDTO();
        dto.setSubjectId(subject.getSubjectId());
        dto.setSubjectName(subject.getSubjectName());
        dto.setDescription(subject.getDescription());
        dto.setCreatedAt(subject.getCreatedAt());
        dto.setUpdatedAt(subject.getUpdatedAt());
        return dto;
    }

    // 1. Lấy tất cả môn học (GET)
    public List<SubjectDTO> getAllSubjects() {
        return subjectRepository.findAll().stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    // 2. Lấy môn học theo ID (GET)
    public SubjectDTO getSubjectById(String id) {
        Subject subject = subjectRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy môn học với ID: " + id));
        return mapToDTO(subject);
    }

    // 3. Tạo môn học mới (POST)
    public SubjectDTO createSubject(SubjectDTO dto) {
        Subject subject = new Subject();
        subject.setSubjectId(java.util.UUID.randomUUID().toString());

        subject.setSubjectName(dto.getSubjectName());
        subject.setDescription(dto.getDescription());

        Subject savedSubject = subjectRepository.save(subject);
        return mapToDTO(savedSubject);
    }

    // 4. Cập nhật thông tin môn học (PUT)
    public SubjectDTO updateSubject(String id, SubjectDTO dto) {
        Subject subject = subjectRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy môn học với ID: " + id));

        subject.setSubjectName(dto.getSubjectName());
        subject.setDescription(dto.getDescription());

        Subject updatedSubject = subjectRepository.save(subject);
        return mapToDTO(updatedSubject);
    }

    // 5. Xóa môn học (DELETE) - Hard delete
    public void deleteSubject(String id) {
        Subject subject = subjectRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy môn học với ID: " + id));
        subjectRepository.delete(subject);
    }
}