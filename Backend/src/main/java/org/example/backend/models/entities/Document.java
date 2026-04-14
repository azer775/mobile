package org.example.backend.models.entities;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

@Getter
@Setter
@Entity
@Table(name = "documents")
public class Document {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Integer id;

    @Column(name = "file_name", length = Integer.MAX_VALUE)
    private String fileName;

    @Column(name = "file_path", length = Integer.MAX_VALUE)
    private String filePath;

    @Column(name = "content_type", length = Integer.MAX_VALUE)
    private String contentType;

    @Column(name = "created_at")
    private Instant createdAt;
}
