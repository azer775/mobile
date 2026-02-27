package org.example.backend.models.dtos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PersonneDto {
    String typePersonne;
    String nomRaisonSociale;
    String nif;
    String contact;
    String adressePostale;
}
