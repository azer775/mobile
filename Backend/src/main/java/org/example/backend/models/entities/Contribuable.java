package org.example.backend.models.entities;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;
import java.util.List;

@Getter
@Setter
@Entity
@Table(name = "contribuables")
public class Contribuable {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Integer id;

    @Column(name = "nif", length = Integer.MAX_VALUE)
    private String nif;

    @Column(name = "type_nif", length = Integer.MAX_VALUE)
    private String typeNif;

    @Column(name = "type_contribuable", nullable = false, length = Integer.MAX_VALUE)
    private String typeContribuable;

    @Column(name = "nom", length = Integer.MAX_VALUE)
    private String nom;

    @Column(name = "post_nom", length = Integer.MAX_VALUE)
    private String postNom;

    @Column(name = "prenom", length = Integer.MAX_VALUE)
    private String prenom;

    @Column(name = "raison_sociale", length = Integer.MAX_VALUE)
    private String raisonSociale;

    @Column(name = "telephone1", nullable = false, length = Integer.MAX_VALUE)
    private String telephone1;

    @Column(name = "telephone2", length = Integer.MAX_VALUE)
    private String telephone2;

    @Column(name = "email", length = Integer.MAX_VALUE)
    private String email;

    @Column(name = "rue", length = Integer.MAX_VALUE)
    private String rue;

    @Column(name = "numero_parcelle", length = Integer.MAX_VALUE)
    private String numeroParcelle;

    @Column(name = "origine_fiche", nullable = false, length = Integer.MAX_VALUE)
    private String origineFiche;

    @Column(name = "statut")
    private Integer statut;

    @Column(name = "gps_latitude")
    private Double gpsLatitude;

    @Column(name = "gps_longitude")
    private Double gpsLongitude;

    @Column(name = "piece_identite_url", length = Integer.MAX_VALUE)
    private String pieceIdentiteUrl;

    @Column(name = "date_inscription")
    private Instant dateInscription;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "cree_par", nullable = false, length = Integer.MAX_VALUE)
    private String creePar;

    @Column(name = "date_maj")
    private Instant dateMaj;

    @Column(name = "maj_par", length = Integer.MAX_VALUE)
    private String majPar;

    @Column(name = "forme_juridique", length = Integer.MAX_VALUE)
    private String formeJuridique;

    @Column(name = "numero_rccm", length = Integer.MAX_VALUE)
    private String numeroRccm;

    @Column(name = "updated_at")
    private Instant updatedAt;
    @OneToMany(cascade = CascadeType.ALL)
    @JoinColumn(name = "contribuable_id")
    List<Document> documents;
    @ManyToOne
    RefTypeActivite refTypeActivite;
    @ManyToOne
    RefZoneType refZoneType;
    @ManyToOne
    RefAvenue refAvenue;
    @ManyToOne
    RefQuartier refQuartier;
    @ManyToOne
    RefCommune refCommune;

}