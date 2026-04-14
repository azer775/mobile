package org.example.backend.models.dtos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ContribuableDto {
    String typeContribuable;
    String nom;
    String prenom;
    String pieceIdentite;
    String nomRaisonSociale;
    String nif;
    String contact;
    String email;
    String adressePostale;
}
