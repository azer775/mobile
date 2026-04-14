package org.example.backend.controllers;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.example.backend.models.dtos.ParcelleDto;
import org.example.backend.services.ParcelleService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/parcelles")
@CrossOrigin(origins = "*")
public class ParcelleController {

    @Autowired
    private ParcelleService parcelleService;

    @Autowired
    private ObjectMapper objectMapper;

    /**
     * Batch — save multiple parcelles with their batiments, contribuables, and photos.
     * Expects a multipart request with:
     *   - "data": JSON string containing List&lt;ParcelleDto&gt; (each with photoCount)
     *   - "photos": ordered photo files (first photoCount files for parcelle 0, etc.)
     */
    @PostMapping(value = "/batch", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<String> saveParcelles(
            @RequestPart("data") String data,
            @RequestPart(value = "photos", required = false) List<MultipartFile> photos) {
        try {
            List<ParcelleDto> dtos = objectMapper.readValue(data, new TypeReference<>() {});
            parcelleService.saveAllWithPhotos(dtos, photos != null ? photos : List.of());
            return ResponseEntity.ok("Opération terminée avec succès. " + dtos.size() + " parcelle(s) enregistrée(s).");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Erreur lors du traitement: " + e.getMessage());
        }
    }

    /**
     * Single — save one parcelle with its batiments and contribuable (JSON only).
     */
    @PostMapping
    public ResponseEntity<String> saveParcelle(@RequestBody ParcelleDto dto) {
        try {
            parcelleService.save(dto);
            return ResponseEntity.ok("Parcelle enregistrée avec succès.");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Erreur lors du traitement: " + e.getMessage());
        }
    }
}
