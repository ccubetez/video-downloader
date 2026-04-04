package com.example.downloader.controller;

import com.example.downloader.service.VideoService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.FileSystemResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/video")
public class VideoController {

    @Autowired
    private VideoService videoService;

    @PostMapping
    public ResponseEntity<Map<String, String>> download(@RequestBody Map<String, String> request) {
        String url = request.get("url");
        try {
            videoService.startDownload(url);
            return ResponseEntity.accepted().body(Map.of("status", "downloading"));
        } catch (IllegalStateException e) {
            return ResponseEntity.status(409).body(Map.of("status", "busy", "message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of("status", "error", "message", e.getMessage()));
        }
    }

    @GetMapping("/status")
    public ResponseEntity<Map<String, String>> getStatus() {
        return ResponseEntity.ok(videoService.getStatus());
    }

    @GetMapping("/file")
    public ResponseEntity<?> getFile() {
        var file = videoService.getVideoFile();
        if (file == null || !file.exists()) {
            return ResponseEntity.status(404).body(Map.of("status", "error", "message", "No video available"));
        }

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"video.mp4\"")
                .contentType(MediaType.parseMediaType("video/mp4"))
                .body(new FileSystemResource(file));
    }

    @DeleteMapping
    public ResponseEntity<Map<String, String>> clear() {
        videoService.clear();
        return ResponseEntity.ok(Map.of("status", "idle"));
    }
}
