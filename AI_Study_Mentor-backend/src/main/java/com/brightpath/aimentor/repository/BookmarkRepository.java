package com.brightpath.aimentor.repository;

import com.brightpath.aimentor.entity.Bookmark;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface BookmarkRepository extends JpaRepository<Bookmark, String> {
    List<Bookmark> findByUserIdOrderByCreatedAtDesc(String userId);
}
