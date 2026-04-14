package org.example.backend.models.entities;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

@Getter
@Setter
@Entity
@Table(name = "unites")
public class Unite {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Integer id;

    @Column(name = "type_unite", length = Integer.MAX_VALUE)
    private String typeUnite;

    @Column(name = "superficie")
    private Double superficie;

    @ManyToOne
    @JoinColumn(name = "contribuable_id")
    private Contribuable locataire;

    @Column(name = "montant_loyer")
    private Double montantLoyer;

    @Column(name = "date_debut_loyer")
    private Instant dateDebutLoyer;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;
}
