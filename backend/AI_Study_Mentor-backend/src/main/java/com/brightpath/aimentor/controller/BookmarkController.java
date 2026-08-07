package com.brightpath.aimentor.controller;
import com.brightpath.aimentor.dto.ApiResponse;
import com.brightpath.aimentor.entity.Bookmark;
import com.brightpath.aimentor.repository.BookmarkRepository;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.*;

@RestController @RequestMapping("/api/bookmarks")
public class BookmarkController {
    private final BookmarkRepository repo;
    public BookmarkController(BookmarkRepository repo) { this.repo = repo; }
    @GetMapping public ApiResponse<List<Bookmark>> list(Authentication a) { return ApiResponse.ok(repo.findByUserIdOrderByCreatedAtDesc(a.getPrincipal().toString())); }
    @PostMapping public ApiResponse<Bookmark> create(Authentication a, @RequestBody Map<String,String> body) {
        Bookmark b = new Bookmark(); b.setBookmarkId(UUID.randomUUID().toString()); b.setUserId(a.getPrincipal().toString());
        b.setQuestionId(body.get("questionId")); b.setFolderName(body.getOrDefault("folderName","Mặc định"));
        return ApiResponse.ok(repo.save(b));
    }
    @DeleteMapping("/{id}") public ApiResponse<String> delete(@PathVariable String id) { repo.deleteById(id); return ApiResponse.ok("Đã xoá",null); }
}
