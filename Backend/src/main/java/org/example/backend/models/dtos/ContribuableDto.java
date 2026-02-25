package org.example.backend.models.dtos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ContribuableDto {
    String nif;
    String typeNif;
    String typeContribuable;
    String nom;
    String postNom;
    String prenom;
    String raisonSociale;
    String telephone1;
    String telephone2;
    String email;
    String rue;
    String numeroParcelle;
    String origineFiche;
    Integer statut;
    Double gpsLatitude;
    Double gpsLongitude;
    String pieceIdentiteUrl;
    Instant dateInscription;
    Instant dateMaj;
    String formeJuridique;
    String numeroRccm;
    Integer refTypeActivite;
    Integer refZoneType;
    Integer refAvenue;
    Integer refQuartier;
    Integer refCommune;
}