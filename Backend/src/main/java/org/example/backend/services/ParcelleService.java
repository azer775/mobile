package org.example.backend.services;

import org.example.backend.models.dtos.BatimentDto;
import org.example.backend.models.dtos.ParcelleDto;
import org.example.backend.models.dtos.PersonneDto;
import org.example.backend.models.entities.*;
import org.example.backend.repositories.ParcelleRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Service
public class ParcelleService {

    @Autowired
    private ParcelleRepository parcelleRepository;

    @Transactional
    public void saveAll(List<ParcelleDto> dtos) {
        List<Parcelle> parcelles = new ArrayList<>();
        for (ParcelleDto dto : dtos) {
            parcelles.add(mapToEntity(dto));
        }
        parcelleRepository.saveAll(parcelles);
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

        // Mapper les personnes
        if (dto.getPersonnes() != null && !dto.getPersonnes().isEmpty()) {
            List<Personne> personnes = new ArrayList<>();
            for (PersonneDto persDto : dto.getPersonnes()) {
                personnes.add(mapPersonneToEntity(persDto));
            }
            parcelle.setPersonnes(personnes);
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
        return batiment;
    }

    private Personne mapPersonneToEntity(PersonneDto dto) {
        Personne personne = new Personne();
        personne.setTypePersonne(dto.getTypePersonne());
        personne.setNomRaisonSociale(dto.getNomRaisonSociale());
        personne.setNif(dto.getNif());
        personne.setContact(dto.getContact());
        personne.setAdressePostale(dto.getAdressePostale());
        personne.setCreatedAt(Instant.now());
        return personne;
    }
}
