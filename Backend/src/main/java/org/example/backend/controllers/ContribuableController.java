package org.example.backend.controllers;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.swagger.v3.oas.annotations.Operation;

import jakarta.servlet.http.HttpServletRequest;
import org.example.backend.models.dtos.ContribuableDto;
import org.example.backend.services.ContribuableService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.multipart.MultipartHttpServletRequest;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/contribuables")
@CrossOrigin(origins = "*")
public class ContribuableController {

    @Autowired
    private ContribuableService contribuableService;

    @Autowired
    private ObjectMapper objectMapper;

    /**
     * Option A — Batch endpoint
     * Consumes multipart/form-data with:
     *   - "data": JSON string containing a List of ContribuableDto
     *   - "creePar": the user who created the records
     *   - "files_0", "files_1", ...: files for each contribuable by index
     */
    @Operation(summary = "Batch save contribuables with files",
            description = "Send a JSON array of ContribuableDto in 'data', and files for each contribuable using 'files_0', 'files_1', etc.")
    @PostMapping(value = "/batch", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<String> saveContribuables(
            @RequestPart("data") String jsonData,
            HttpServletRequest request
    ) {
        try {
            // Parse the JSON string into a list of DTOs
            List<ContribuableDto> dtos = objectMapper.readValue(jsonData, new TypeReference<>() {
            });

            // Collect files by index from request parts named files_0, files_1, ...
            Map<Integer, List<MultipartFile>> filesMap = new HashMap<>();

            if (request instanceof MultipartHttpServletRequest multipartRequest) {
                for (int i = 0; i < dtos.size(); i++) {
                    String partName = "files_" + i;
                    List<MultipartFile> files = multipartRequest.getFiles(partName);
                    if (!files.isEmpty()) {
                        filesMap.put(i, files);
                    }
                }
            }

            contribuableService.saveContribuables(dtos, filesMap);

            return ResponseEntity.ok("Opération terminée avec succès. " + dtos.size() + " contribuable(s) enregistré(s).");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Erreur lors du traitement: " + e.getMessage());
        }
    }

    /**
     * Option B — Single contribuable endpoint (for Swagger testing)
     * Consumes multipart/form-data with:
     *   - "data": JSON string containing a single ContribuableDto
     *   - "creePar": the user who created the record
     *   - "documents": optional list of files
     */
    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<String> saveContribuable(
            @RequestPart("data") String jsonData,
            @RequestParam("creePar") String creePar,
            @RequestParam(value = "documents", required = false) List<MultipartFile> documents
    ) {
        try {
            ContribuableDto dto = objectMapper.readValue(jsonData, ContribuableDto.class);
            contribuableService.saveContribuable(dto, creePar, documents);
            return ResponseEntity.ok("Contribuable enregistré avec succès.");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Erreur lors du traitement: " + e.getMessage());
        }
    }
}

