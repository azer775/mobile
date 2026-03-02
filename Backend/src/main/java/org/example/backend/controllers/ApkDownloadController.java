package org.example.backend.controllers;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Stream;

@RestController
@RequestMapping("/api/apk")
@CrossOrigin(origins = "*")
public class ApkDownloadController {

    private final Path apkStorageDir;

    public ApkDownloadController(@Value("${apk.storage-dir:apk}") String apkStorageDir) {
        this.apkStorageDir = Paths.get(apkStorageDir).toAbsolutePath().normalize();
        try {
            Files.createDirectories(this.apkStorageDir);
        } catch (IOException e) {
            throw new RuntimeException("Failed to initialize APK storage directory", e);
        }
    }

    @GetMapping("/latest")
    public ResponseEntity<Map<String, Object>> getLatestApk() {
        try (Stream<Path> files = Files.list(apkStorageDir)) {
            Optional<Path> latest = files
                    .filter(path -> !Files.isDirectory(path))
                    .filter(path -> path.getFileName().toString().toLowerCase().endsWith(".apk"))
                    .max(Comparator.comparing(path -> {
                        try {
                            return Files.getLastModifiedTime(path);
                        } catch (IOException e) {
                            return null;
                        }
                    }, Comparator.nullsFirst(Comparator.naturalOrder())));

            if (latest.isEmpty()) {
                return ResponseEntity.notFound().build();
            }

            Path apkFile = latest.get();
            return ResponseEntity.ok(Map.of(
                    "fileName", apkFile.getFileName().toString(),
                    "size", Files.size(apkFile),
                    "lastModified", Files.getLastModifiedTime(apkFile).toMillis()
            ));
        } catch (IOException e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping("/pdfs")
    public ResponseEntity<List<Map<String, Object>>> listPdfs() {
        List<Map<String, Object>> pdfs = new ArrayList<>();
        try (Stream<Path> files = Files.list(apkStorageDir)) {
            files.filter(path -> !Files.isDirectory(path))
                 .filter(path -> path.getFileName().toString().toLowerCase().endsWith(".pdf"))
                 .sorted(Comparator.comparing((Path path) -> {
                     try {
                         return Files.getLastModifiedTime(path);
                     } catch (IOException e) {
                         return null;
                     }
                 }, Comparator.nullsFirst(Comparator.naturalOrder())).reversed())
                 .forEach(path -> {
                     try {
                         Map<String, Object> info = new HashMap<>();
                         info.put("fileName", path.getFileName().toString());
                         info.put("size", Files.size(path));
                         info.put("lastModified", Files.getLastModifiedTime(path).toMillis());
                         pdfs.add(info);
                     } catch (IOException ignored) {}
                 });
        } catch (IOException e) {
            return ResponseEntity.internalServerError().build();
        }
        return ResponseEntity.ok(pdfs);
    }

    @GetMapping("/download/{fileName:.+}")
    public ResponseEntity<Resource> downloadApk(@PathVariable String fileName) {
        try {
            Path file = apkStorageDir.resolve(fileName).normalize();

            if (!file.startsWith(apkStorageDir)) {
                return ResponseEntity.badRequest().build();
            }

            if (!Files.exists(file) || Files.isDirectory(file)) {
                return ResponseEntity.notFound().build();
            }

            Resource resource = new UrlResource(file.toUri());

            return ResponseEntity.ok()
                    .contentType(MediaType.APPLICATION_OCTET_STREAM)
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + file.getFileName() + "\"")
                    .header(HttpHeaders.CONTENT_LENGTH, String.valueOf(Files.size(file)))
                    .body(resource);
        } catch (IOException e) {
            return ResponseEntity.internalServerError().build();
        }
    }
}
