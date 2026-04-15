package org.example.backend.services;

import org.example.backend.models.dtos.BatimentDto;
import org.example.backend.models.dtos.ParcelleDto;
import org.example.backend.models.dtos.ContribuableDto;
import org.example.backend.models.dtos.UniteDto;
import org.example.backend.models.entities.*;
import org.example.backend.repositories.ContribuableRepository;
import org.example.backend.repositories.ParcelleRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
public class ParcelleService {

    @Autowired
    private ParcelleRepository parcelleRepository;

    @Autowired
    private ContribuableRepository contribuableRepository;

    @Autowired
    private FileService fileService;

    @Transactional
    public void saveAll(List<ParcelleDto> dtos) {
        List<Parcelle> parcelles = new ArrayList<>();
        for (ParcelleDto dto : dtos) {
            parcelles.add(mapToEntity(dto));
        }
        parcelleRepository.saveAll(parcelles);
    }

    @Transactional
    public void saveAllWithPhotos(List<ParcelleDto> dtos, List<MultipartFile> photos) throws IOException {
        int photoOffset = 0;
        for (ParcelleDto dto : dtos) {
            Parcelle parcelle = mapToEntity(dto);

            int count = dto.getPhotoCount() != null ? dto.getPhotoCount() : 0;
            List<Document> documents = new ArrayList<>();
            for (int j = 0; j < count && (photoOffset + j) < photos.size(); j++) {
                MultipartFile file = photos.get(photoOffset + j);
                String savedName = fileService.saveFile(file);

                Document doc = new Document();
                doc.setFileName(file.getOriginalFilename());
                doc.setFilePath(savedName);
                doc.setContentType(file.getContentType());
                doc.setCreatedAt(Instant.now());
                documents.add(doc);
            }
            parcelle.setDocuments(documents);
            photoOffset += count;

            parcelleRepository.save(parcelle);
        }
    }

    @Transactional
    public void save(ParcelleDto dto) {
        parcelleRepository.save(mapToEntity(dto));
    }

    private Parcelle mapToEntity(ParcelleDto dto) {
        Parcelle parcelle = new Parcelle();

        parcelle.setCodeParcelle(dto.getCodeParcelle());
        parcelle.setReferenceCadastrale(dto.getReferenceCadastrale());
        parcelle.setNumeroAdresse(dto.getNumeroAdresse());
        parcelle.setRue(dto.getRue());
        parcelle.setNumeroParcelle(dto.getNumeroParcelle());
        parcelle.setSuperficieM2(dto.getSuperficieM2());
        parcelle.setGpsLat(dto.getGpsLat());
        parcelle.setGpsLon(dto.getGpsLon());
        parcelle.setStatutParcelle(dto.getStatutParcelle());
        parcelle.setSourceDonnee(dto.getSourceDonnee());
        parcelle.setCreatedAt(Instant.now());

        // Résolution des références par ID (objet avec ID uniquement, pas de requête DB)
        if (dto.getCommune() != null) {
            RefCommune ref = new RefCommune();
            ref.setId(dto.getCommune());
            parcelle.setCommune(ref);
        }

        if (dto.getQuartier() != null) {
            RefQuartier ref = new RefQuartier();
            ref.setId(dto.getQuartier());
            parcelle.setQuartier(ref);
        }

        if (dto.getRueAvenue() != null) {
            RefAvenue ref = new RefAvenue();
            ref.setId(dto.getRueAvenue());
            parcelle.setRueAvenue(ref);
        }

        // Mapper les bâtiments
        if (dto.getBatiments() != null && !dto.getBatiments().isEmpty()) {
            List<Batiment> batiments = new ArrayList<>();
            for (BatimentDto batDto : dto.getBatiments()) {
                batiments.add(mapBatimentToEntity(batDto));
            }
            parcelle.setBatiments(batiments);
        }

        // Mapper le contribuable (propriétaire)
        if (dto.getContribuable() != null) {
            parcelle.setContribuable(findOrCreateContribuable(dto.getContribuable()));
        }

        return parcelle;
    }

    private Batiment mapBatimentToEntity(BatimentDto dto) {
        Batiment batiment = new Batiment();
        batiment.setTypeBatiment(dto.getTypeBatiment());
        batiment.setNombreEtages(dto.getNombreEtages());
        batiment.setAnneeConstruction(dto.getAnneeConstruction());
        batiment.setSurfaceBatieM2(dto.getSurfaceBatieM2());
        batiment.setUsagePrincipal(dto.getUsagePrincipal());
        batiment.setStatutBatiment(dto.getStatutBatiment());
        batiment.setCreatedAt(Instant.now());

        // Mapper les unités
        if (dto.getUnites() != null && !dto.getUnites().isEmpty()) {
            List<Unite> unites = new ArrayList<>();
            for (UniteDto uniteDto : dto.getUnites()) {
                unites.add(mapUniteToEntity(uniteDto));
            }
            batiment.setUnites(unites);
        }

        return batiment;
    }

    private Unite mapUniteToEntity(UniteDto dto) {
        Unite unite = new Unite();
        unite.setTypeUnite(dto.getTypeUnite());
        unite.setSuperficie(dto.getSuperficie());
        unite.setMontantLoyer(dto.getMontantLoyer());
        if (dto.getDateDebutLoyer() != null) {
            unite.setDateDebutLoyer(parseFlutterDate(dto.getDateDebutLoyer()));
        }
        unite.setCreatedAt(Instant.now());

        // Mapper le locataire (contribuable)
        if (dto.getLocataire() != null) {
            unite.setLocataire(findOrCreateContribuable(dto.getLocataire()));
        }

        return unite;
    }

    private Instant parseFlutterDate(String dateStr) {
        try {
            return Instant.parse(dateStr);
        } catch (DateTimeParseException e) {
            // Flutter sends dates without Z suffix (e.g. 2024-01-15T00:00:00.000)
            return LocalDateTime.parse(dateStr).toInstant(ZoneOffset.UTC);
        }
    }

    private Contribuable findOrCreateContribuable(ContribuableDto dto) {
        String type = dto.getTypeContribuable();

        // Search by pieceIdentite for physique, nomRaisonSociale for morale
        if ("physique".equalsIgnoreCase(type)) {
            String key = dto.getPieceIdentite();
            if (key != null && !key.isBlank()) {
                Optional<Contribuable> existing = contribuableRepository.findFirstByPieceIdentite(key);
                if (existing.isPresent()) return existing.get();
            }
        } else if ("morale".equalsIgnoreCase(type)) {
            String key = dto.getNomRaisonSociale();
            if (key != null && !key.isBlank()) {
                Optional<Contribuable> existing = contribuableRepository.findFirstByNomRaisonSociale(key);
                if (existing.isPresent()) return existing.get();
            }
        }

        // No match found — create new
        Contribuable contribuable = new Contribuable();
        contribuable.setTypeContribuable(dto.getTypeContribuable());
        contribuable.setNom(dto.getNom());
        contribuable.setPrenom(dto.getPrenom());
        contribuable.setPieceIdentite(dto.getPieceIdentite());
        contribuable.setNomRaisonSociale(dto.getNomRaisonSociale());
        contribuable.setNif(dto.getNif());
        contribuable.setContact(dto.getContact());
        contribuable.setEmail(dto.getEmail());
        contribuable.setAdressePostale(dto.getAdressePostale());
        contribuable.setCreatedAt(Instant.now());
        return contribuableRepository.save(contribuable);
    }
}
