package org.example.backend.models.entities;

import jakarta.persistence.*;
import lombok.Data;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;
import java.util.List;

@Getter
@Setter
@Data
@Entity
@Table(name = "contribuables")
public class Contribuable {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Integer id;

    @Column(name = "type_contribuable", nullable = false, length = Integer.MAX_VALUE)
    private String typeContribuable;

    @Column(name = "nom", length = Integer.MAX_VALUE)
    private String nom;

    @Column(name = "prenom", length = Integer.MAX_VALUE)
    private String prenom;

    @Column(name = "piece_identite", length = Integer.MAX_VALUE)
    private String pieceIdentite;

    @Column(name = "nom_raison_sociale", length = Integer.MAX_VALUE)
    private String nomRaisonSociale;

    @Column(name = "nif", length = Integer.MAX_VALUE)
    private String nif;

    @Column(name = "contact", length = Integer.MAX_VALUE)
    private String contact;

    @Column(name = "email", length = Integer.MAX_VALUE)
    private String email;

    @Column(name = "adresse_postale", length = Integer.MAX_VALUE)
    private String adressePostale;

    // Legacy NOT NULL columns (required by existing DB schema)
    @Column(name = "cree_par", nullable = false, length = Integer.MAX_VALUE)
    private String creePar = "mobile-app";

    @Column(name = "origine_fiche", nullable = false, length = Integer.MAX_VALUE)
    private String origineFiche = "terrain";

    @Column(name = "telephone1", nullable = false, length = Integer.MAX_VALUE)
    private String telephone1 = "";


    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;

    @OneToMany(mappedBy = "contribuable")
    private List<Parcelle> parcelles;

}
