package org.example.backend.models.dtos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UniteDto {
    String typeUnite;
    Double superficie;
    ContribuableDto locataire;
    Double montantLoyer;
    String dateDebutLoyer;
}
