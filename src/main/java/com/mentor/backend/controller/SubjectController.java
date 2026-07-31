package com.mentor.backend.controller;

import com.mentor.backend.dto.SubjectDTO;
import com.mentor.backend.service.SubjectService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/subjects")
public class SubjectController {

    @Autowired
    private SubjectService subjectService;

    // Lấy danh sách môn học
    @GetMapping
    public ResponseEntity<List<SubjectDTO>> getAllSubjects() {
        return ResponseEntity.ok(subjectService.getAllSubjects());
    }

    // Lấy chi tiết môn học theo ID
    @GetMapping("/{id}")
    public ResponseEntity<SubjectDTO> getSubjectById(@PathVariable String id) {
        return ResponseEntity.ok(subjectService.getSubjectById(id));
    }

    // Thêm mới môn học
    @PostMapping
    public ResponseEntity<SubjectDTO> createSubject(@RequestBody SubjectDTO dto) {
        return ResponseEntity.ok(subjectService.createSubject(dto));
    }

    // Cập nhật môn học
    @PutMapping("/{id}")
    public ResponseEntity<SubjectDTO> updateSubject(@PathVariable String id, @RequestBody SubjectDTO dto) {
        return ResponseEntity.ok(subjectService.updateSubject(id, dto));
    }

    // Xóa môn học
    @DeleteMapping("/{id}")
    public ResponseEntity<String> deleteSubject(@PathVariable String id) {
        subjectService.deleteSubject(id);
        return ResponseEntity.ok("Đã xóa môn học thành công!");
    }
}