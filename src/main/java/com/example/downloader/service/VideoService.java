package com.example.downloader.service;

import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import org.springframework.stereotype.Service;

import java.io.BufferedReader;
import java.io.File;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;

@Service
public class VideoService {

    private Path workDir;
    private volatile Map<String, String> status = Map.of("status", "idle");
    private volatile File currentFile;
    private volatile CompletableFuture<Void> currentTask;

    @PostConstruct
    public void init() throws Exception {
        String dir = System.getProperty("downloader.temp.dir", "/tmp/video-downloader");
        workDir = Path.of(dir);
        Files.createDirectories(workDir);
        System.out.println("VideoService initialized. Work dir: " + workDir);

        // Check yt-dlp is available
        try {
            ProcessBuilder pb = new ProcessBuilder(getYtDlpPath(), "--version");
            Process p = pb.start();
            p.waitFor();
            String version = new BufferedReader(new InputStreamReader(p.getInputStream())).readLine();
            System.out.println("yt-dlp version: " + version);
        } catch (Exception e) {
            System.err.println("WARNING: yt-dlp not available. Downloads will fail.");
            System.err.println("Error: " + e.getMessage());
        }
    }

    @PreDestroy
    public void cleanup() {
        clear();
    }

    public synchronized void startDownload(String url) {
        String currentStatus = status.get("status");
        if (!"idle".equals(currentStatus) && !"ready".equals(currentStatus) && !"error".equals(currentStatus)) {
            throw new IllegalStateException("Download already in progress");
        }

        clear();

        String jobId = UUID.randomUUID().toString().substring(0, 8);
        System.out.println("Starting download job " + jobId + " for URL: " + url);

        status = Map.of("status", "downloading");

        currentTask = CompletableFuture.runAsync(() -> doDownload(url, jobId))
                .exceptionally(ex -> {
                    System.err.println("Download failed: " + ex.getMessage());
                    status = Map.of("status", "error", "message", ex.getMessage());
                    return null;
                });
    }

    private void doDownload(String url, String jobId) {
        try {
            String filename = "video_" + jobId + ".mp4";
            Path outputPath = workDir.resolve(filename);

            ProcessBuilder pb = new ProcessBuilder(
                    getYtDlpPath(),
                    "-f", "best[height<=1080]",
                    "--merge-output-format", "mp4",
                    "-o", outputPath.toString(),
                    "--no-playlist",
                    url
            );

            pb.redirectErrorStream(true);
            Process process = pb.start();

            try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    System.out.println("[yt-dlp] " + line);
                }
            }

            int exitCode = process.waitFor();
            if (exitCode != 0) {
                throw new RuntimeException("yt-dlp exited with code " + exitCode);
            }

            currentFile = outputPath.toFile();
            status = Map.of("status", "ready");
            System.out.println("Download completed: " + outputPath);

        } catch (Exception e) {
            throw new RuntimeException("Download failed: " + e.getMessage(), e);
        }
    }

    public Map<String, String> getStatus() {
        return status;
    }

    public File getVideoFile() {
        return currentFile;
    }

    public synchronized void clear() {
        if (currentTask != null && !currentTask.isDone()) {
            currentTask.cancel(true);
        }

        if (currentFile != null && currentFile.exists()) {
            if (currentFile.delete()) {
                System.out.println("Deleted: " + currentFile);
            }
        }

        currentFile = null;
        currentTask = null;
        status = Map.of("status", "idle");
    }

    private String getYtDlpPath() {
        // First, try to find embedded yt-dlp
        try {
            // Try to extract from resources to temp directory
            Path tempDir = Path.of(System.getProperty("java.io.tmpdir"), "video-downloader-bin");
            Files.createDirectories(tempDir);
            Path ytDlpPath = tempDir.resolve("yt-dlp");

            if (!Files.exists(ytDlpPath)) {
                // Extract from resources
                try (InputStream is = getClass().getResourceAsStream("/bin/yt-dlp")) {
                    if (is != null) {
                        Files.copy(is, ytDlpPath);
                        ytDlpPath.toFile().setExecutable(true);
                        System.out.println("Extracted yt-dlp to: " + ytDlpPath);
                    }
                }
            }

            if (Files.exists(ytDlpPath)) {
                return ytDlpPath.toString();
            }
        } catch (Exception e) {
            System.err.println("Failed to extract embedded yt-dlp: " + e.getMessage());
        }

        // Fallback to system PATH
        return "yt-dlp";
    }
}
