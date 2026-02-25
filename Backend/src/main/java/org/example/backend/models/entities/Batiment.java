package org.example.backend.models.entities;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.time.Instant;

@Getter
@Setter
@Entity
@Table(name = "batiments")
public class Batiment {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Integer id;

//    @ManyToOne(fetch = FetchType.LAZY)
//    @OnDelete(action = OnDeleteAction.CASCADE)
//    @JoinColumn(name = "parcelle_id")
//    private Parcelle parcelle;

    @NotNull
    @Column(name = "type_batiment", nullable = false, length = Integer.MAX_VALUE)
    private String typeBatiment;

    @Column(name = "nombre_etages")
    private Integer nombreEtages;

    @Column(name = "annee_construction")
    private Integer anneeConstruction;

    @Column(name = "surface_batie_m2")
    private Double surfaceBatieM2;

    @NotNull
    @Column(name = "usage_principal", nullable = false, length = Integer.MAX_VALUE)
    private String usagePrincipal;

    @NotNull
    @Column(name = "statut_batiment", nullable = false, length = Integer.MAX_VALUE)
    private String statutBatiment;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;


}