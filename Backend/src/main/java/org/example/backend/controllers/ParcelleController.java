package org.example.backend.controllers;

import org.example.backend.models.dtos.ParcelleDto;
import org.example.backend.services.ParcelleService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/parcelles")
@CrossOrigin(origins = "*")
public class ParcelleController {

    @Autowired
    private ParcelleService parcelleService;

    /**
     * Batch — save multiple parcelles with their batiments and personnes.
     * Expects a JSON array of ParcelleDto.
     */
    @PostMapping("/batch")
    public ResponseEntity<String> saveParcelles(@RequestBody List<ParcelleDto> dtos) {
        try {
            parcelleService.saveAll(dtos);
            return ResponseEntity.ok("Opération terminée avec succès. " + dtos.size() + " parcelle(s) enregistrée(s).");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Erreur lors du traitement: " + e.getMessage());
        }
    }

    /**
     * Single — save one parcelle with its batiments and personnes.
     * Expects a single ParcelleDto JSON object.
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
