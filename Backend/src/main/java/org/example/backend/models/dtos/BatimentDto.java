package org.example.backend.models.dtos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BatimentDto {
    String typeBatiment;
    Integer nombreEtages;
    Integer anneeConstruction;
    Double surfaceBatieM2;
    String usagePrincipal;
    String statutBatiment;
}
