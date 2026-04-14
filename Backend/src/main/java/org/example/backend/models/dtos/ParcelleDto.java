package org.example.backend.models.dtos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ParcelleDto {
    String codeParcelle;
    String referenceCadastrale;
    String numeroAdresse;
    String rue;
    String numeroParcelle;
    Double superficieM2;
    Double gpsLat;
    Double gpsLon;
    String statutParcelle;
    String sourceDonnee;

    // Reference IDs
    Integer commune;
    Integer quartier;
    Integer rueAvenue;

    // Nested children
    List<BatimentDto> batiments;
    ContribuableDto contribuable;

    // Transient — used in multipart upload to map photo files to parcelles
    Integer photoCount;
}
