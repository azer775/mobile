package org.example.backend.services;

import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.PathResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.UUID;

@Service
public class FileService {

    private static final Logger log = LoggerFactory.getLogger(FileService.class);

    @Value("${file.upload-dir}")
    private String uploadDir;

    private Path uploadPath;

    @PostConstruct
    public void init() {
        log.info("file.upload-dir raw value: '{}'", uploadDir);
        uploadPath = Paths.get(uploadDir).toAbsolutePath().normalize();
        log.info("Resolved upload path: {}", uploadPath);
        try {
            Files.createDirectories(uploadPath);
        } catch (IOException e) {
            throw new UncheckedIOException("Failed to create upload directory: " + uploadPath, e);
        }
    }

    public String saveFile(MultipartFile file) throws IOException {
        String originalFilename = file.getOriginalFilename();
        // Strip path separators to prevent directory traversal
        String safeName = (originalFilename != null)
                ? Paths.get(originalFilename).getFileName().toString()
                : "file";
        String uniqueFilename = UUID.randomUUID() + "_" + safeName;

        Path targetPath = uploadPath.resolve(uniqueFilename).normalize();
        // Verify target stays within upload directory
        if (!targetPath.startsWith(uploadPath)) {
            throw new IllegalArgumentException("Invalid file name");
        }

        Files.copy(file.getInputStream(), targetPath, StandardCopyOption.REPLACE_EXISTING);
        return uniqueFilename;
    }

    public Resource getFile(String fileName) {
        if (fileName == null || fileName.isBlank()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "File not found");
        }

        Path path = uploadPath.resolve(fileName).normalize();
        // Verify resolved path stays within upload directory
        if (!path.startsWith(uploadPath)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid file path");
        }

        if (!Files.exists(path) || !Files.isRegularFile(path)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "File not found");
        }

        return new PathResource(path);
    }
}
