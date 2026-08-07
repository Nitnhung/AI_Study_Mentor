package com.brightpath.aimentor.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
public class HealthController {

    @Value("${gemini.model}") private String model;
    @Value("${gemini.api-key}") private String apiKey;

    @GetMapping("/health")
    public Map<String, Object> health() {
        return Map.of(
            "status", "ok",
            "aiProvider", "gemini",
            "model", model,
            "apiKeyConfigured", apiKey != null && !apiKey.isBlank()
        );
    }
}
