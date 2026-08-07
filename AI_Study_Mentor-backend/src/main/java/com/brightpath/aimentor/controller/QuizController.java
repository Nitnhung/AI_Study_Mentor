package com.brightpath.aimentor.controller;
import com.brightpath.aimentor.dto.*;
import com.brightpath.aimentor.service.QuizService;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.*;

@RestController @RequestMapping("/api/quiz")
public class QuizController {
    private final QuizService svc;
    public QuizController(QuizService svc) { this.svc = svc; }
    @PostMapping("/generate") public ApiResponse<Map<String,Object>> gen(Authentication a, @RequestBody QuizGenerateRequest r) { return ApiResponse.ok(svc.generateQuiz(a.getPrincipal().toString(), r)); }
    @PostMapping("/grade") public ApiResponse<Map<String,Object>> grade(Authentication a, @RequestBody QuizGradeRequest r) { return ApiResponse.ok(svc.gradeAnswer(a.getPrincipal().toString(), r.getQqId(), r.getUserAnswer())); }
}
