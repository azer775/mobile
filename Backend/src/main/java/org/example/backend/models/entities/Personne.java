package org.example.backend.models.entities;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.time.Instant;

@Getter
@Setter
@Entity
@Table(name = "personnes")
public class Personne {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Integer id;

    @Column(name = "type_personne", nullable = false, length = Integer.MAX_VALUE)
    private String typePersonne;

    @Column(name = "nom_raison_sociale", length = Integer.MAX_VALUE)
    private String nomRaisonSociale;

    @Column(name = "nif", length = Integer.MAX_VALUE)
    private String nif;

    @Column(name = "contact", length = Integer.MAX_VALUE)
    private String contact;

    @Column(name = "adresse_postale", length = Integer.MAX_VALUE)
    private String adressePostale;


    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;

}