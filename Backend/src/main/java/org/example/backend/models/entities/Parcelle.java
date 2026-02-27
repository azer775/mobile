package org.example.backend.models.entities;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.sql.Ref;
import java.time.Instant;
import java.util.List;

@Getter
@Setter
@Entity
@Table(name = "parcelles")
public class Parcelle {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Integer id;

    @Column(name = "code_parcelle", length = Integer.MAX_VALUE)
    private String codeParcelle;

    @Column(name = "reference_cadastrale", length = Integer.MAX_VALUE)
    private String referenceCadastrale;

    @ManyToOne
    private RefCommune commune;

    @ManyToOne
    private RefQuartier quartier;

    @ManyToOne
    private RefAvenue rueAvenue;

    @Column(name = "numero_adresse", length = Integer.MAX_VALUE)
    private String numeroAdresse;

    @Column(name = "rue", length = Integer.MAX_VALUE)
    private String rue;

    @Column(name = "numero_parcelle", length = Integer.MAX_VALUE)
    private String numeroParcelle;

    @Column(name = "superficie_m2")
    private Double superficieM2;

    @Column(name = "gps_lat")
    private Double gpsLat;

    @Column(name = "gps_lon")
    private Double gpsLon;

    @Column(name = "statut_parcelle", nullable = false, length = Integer.MAX_VALUE)
    private String statutParcelle;

    @Column(name = "date_creation")
    private Instant dateCreation;

    @Column(name = "date_mise_a_jour")
    private Instant dateMiseAJour;

    @Column(name = "source_donnee", length = Integer.MAX_VALUE)
    private String sourceDonnee;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;

    @OneToMany(cascade = CascadeType.ALL)
    @JoinColumn(name = "parcelle_id")
    private List<Batiment> batiments;
    @OneToMany(cascade = CascadeType.ALL)
    @JoinColumn(name = "parcelle_id")
    private List<Personne> personnes;



}