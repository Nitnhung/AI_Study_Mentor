package com.brightpath.aimentor.controller;
import com.brightpath.aimentor.dto.*;
import com.brightpath.aimentor.service.QuestionService;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.*;

@RestController @RequestMapping("/api/ai")
public class QuestionController {
    private final QuestionService svc;
    public QuestionController(QuestionService svc) { this.svc = svc; }
    @PostMapping("/ask") public ApiResponse<AiAnswerResponse> ask(Authentication a, @RequestBody AskQuestionRequest r) { return ApiResponse.ok(svc.askQuestion(a.getPrincipal().toString(), r)); }
    @GetMapping("/history") public ApiResponse<List<Map<String,Object>>> history(Authentication a) { return ApiResponse.ok(svc.getHistory(a.getPrincipal().toString())); }
}
