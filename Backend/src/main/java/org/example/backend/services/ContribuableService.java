package org.example.backend.services;

import jakarta.annotation.PostConstruct;
import org.example.backend.models.dtos.ContribuableDto;
import org.example.backend.models.entities.*;
import org.example.backend.repositories.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class ContribuableService {

    @Autowired
    private ContribuableRepository contribuableRepository;

    @Value("${file.upload-dir}")
    private String uploadDir;

    private Path uploadPath;

    @PostConstruct
    public void init() {
        uploadPath = Paths.get(uploadDir).toAbsolutePath().normalize();
        try {
            Files.createDirectories(uploadPath);
        } catch (IOException e) {
            throw new RuntimeException("Impossible de créer le répertoire d'upload: " + uploadPath, e);
        }
    }

    @Transactional
    public void saveContribuables(List<ContribuableDto> dtos, Map<Integer, List<MultipartFile>> filesMap) {
        List<Contribuable> contribuables = new ArrayList<>();

        for (int i = 0; i < dtos.size(); i++) {
            Contribuable contribuable = mapToEntity(dtos.get(i));

            // Sauvegarder les fichiers et créer les entités Document
            List<MultipartFile> files = filesMap != null ? filesMap.get(i) : null;
            if (files != null && !files.isEmpty()) {
                List<Document> documents = new ArrayList<>();
                for (MultipartFile file : files) {
                    if (!file.isEmpty()) {
                        String fileUrl = saveFile(file);
                        Document document = new Document();
                        document.setUrl(fileUrl);
                        documents.add(document);
                    }
                }
                contribuable.setDocuments(documents);
            }

            contribuables.add(contribuable);
        }

        contribuableRepository.saveAll(contribuables);
    }

    @Transactional
    public void saveContribuable(ContribuableDto dto, String creePar, List<MultipartFile> files) {
        Contribuable contribuable = mapToEntity(dto);

        if (files != null && !files.isEmpty()) {
            List<Document> documents = new ArrayList<>();
            for (MultipartFile file : files) {
                if (!file.isEmpty()) {
                    String fileUrl = saveFile(file);
                    Document document = new Document();
                    document.setUrl(fileUrl);
                    documents.add(document);
                }
            }
            contribuable.setDocuments(documents);
        }

        contribuableRepository.save(contribuable);
    }

    private Contribuable mapToEntity(ContribuableDto dto) {
        Contribuable contribuable = new Contribuable();

        contribuable.setNif(dto.getNif());
        contribuable.setTypeNif(dto.getTypeNif());
        contribuable.setTypeContribuable(dto.getTypeContribuable());
        contribuable.setNom(dto.getNom());
        contribuable.setPostNom(dto.getPostNom());
        contribuable.setPrenom(dto.getPrenom());
        contribuable.setRaisonSociale(dto.getRaisonSociale());
        contribuable.setTelephone1(dto.getTelephone1());
        contribuable.setTelephone2(dto.getTelephone2());
        contribuable.setEmail(dto.getEmail());
        contribuable.setRue(dto.getRue());
        contribuable.setNumeroParcelle(dto.getNumeroParcelle());
        contribuable.setOrigineFiche(dto.getOrigineFiche());
        contribuable.setStatut(dto.getStatut());
        contribuable.setGpsLatitude(dto.getGpsLatitude());
        contribuable.setGpsLongitude(dto.getGpsLongitude());
        contribuable.setPieceIdentiteUrl(dto.getPieceIdentiteUrl());
        contribuable.setDateInscription(dto.getDateInscription());
        contribuable.setDateMaj(dto.getDateMaj());
        contribuable.setFormeJuridique(dto.getFormeJuridique());
        contribuable.setNumeroRccm(dto.getNumeroRccm());
        contribuable.setCreatedAt(Instant.now());
        contribuable.setCreePar("system");

        // Résolution des références par ID (objet avec ID uniquement, pas de requête DB)
        if (dto.getRefTypeActivite() != null) {
            RefTypeActivite ref = new RefTypeActivite();
            ref.setId(dto.getRefTypeActivite());
            contribuable.setRefTypeActivite(ref);
        }

        if (dto.getRefZoneType() != null) {
            RefZoneType ref = new RefZoneType();
            ref.setId(dto.getRefZoneType());
            contribuable.setRefZoneType(ref);
        }

        if (dto.getRefAvenue() != null) {
            RefAvenue ref = new RefAvenue();
            ref.setId(dto.getRefAvenue());
            contribuable.setRefAvenue(ref);
        }

        if (dto.getRefQuartier() != null) {
            RefQuartier ref = new RefQuartier();
            ref.setId(dto.getRefQuartier());
            contribuable.setRefQuartier(ref);
        }

        if (dto.getRefCommune() != null) {
            RefCommune ref = new RefCommune();
            ref.setId(dto.getRefCommune());
            contribuable.setRefCommune(ref);
        }

        return contribuable;
    }

    private String saveFile(MultipartFile file) {
        try {
            String originalFilename = file.getOriginalFilename();
            String uniqueFilename = UUID.randomUUID() + "_" + (originalFilename != null ? originalFilename : "file");
            Path targetPath = uploadPath.resolve(uniqueFilename);
            Files.copy(file.getInputStream(), targetPath, StandardCopyOption.REPLACE_EXISTING);
            return targetPath.toString();
        } catch (IOException e) {
            throw new RuntimeException("Erreur lors de la sauvegarde du fichier: " + file.getOriginalFilename(), e);
        }
    }
}
