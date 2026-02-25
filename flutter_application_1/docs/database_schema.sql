-- =============================================
-- PostgreSQL Database Schema
-- Generated from Flutter SQLite schema
-- =============================================

-- Reference Tables
-- =============================================

CREATE TABLE ref_type_activite (
    id SERIAL PRIMARY KEY,
    libelle TEXT NOT NULL
);

INSERT INTO ref_type_activite (libelle) VALUES
    ('Commerce général'),
    ('Agriculture'),
    ('Artisanat'),
    ('Services'),
    ('Transport'),
    ('Restauration'),
    ('Hôtellerie'),
    ('Construction'),
    ('Industrie'),
    ('Santé'),
    ('Éducation'),
    ('Télécommunications'),
    ('Banque et Finance'),
    ('Immobilier'),
    ('Autre');

CREATE TABLE ref_zone_type (
    id SERIAL PRIMARY KEY,
    libelle TEXT NOT NULL
);

INSERT INTO ref_zone_type (libelle) VALUES
    ('Zone urbaine'),
    ('Zone périurbaine'),
    ('Zone rurale'),
    ('Zone industrielle'),
    ('Zone commerciale'),
    ('Zone résidentielle'),
    ('Zone mixte');

CREATE TABLE ref_commune (
    id SERIAL PRIMARY KEY,
    libelle TEXT NOT NULL
);

INSERT INTO ref_commune (libelle) VALUES
    ('Bandalungwa'),
    ('Barumbu'),
    ('Bumbu'),
    ('Gombe'),
    ('Kalamu'),
    ('Kasa-Vubu'),
    ('Kimbanseke'),
    ('Kinshasa'),
    ('Kintambo'),
    ('Kisenso'),
    ('Lemba'),
    ('Limete'),
    ('Lingwala'),
    ('Makala'),
    ('Maluku'),
    ('Masina'),
    ('Matete'),
    ('Mont-Ngafula'),
    ('Ndjili'),
    ('Ngaba'),
    ('Ngaliema'),
    ('Ngiri-Ngiri'),
    ('Nsele'),
    ('Selembao');

CREATE TABLE ref_quartier (
    id SERIAL PRIMARY KEY,
    libelle TEXT NOT NULL
);

INSERT INTO ref_quartier (libelle) VALUES
    ('Centre-ville'),
    ('Matonge'),
    ('Yolo'),
    ('Righini'),
    ('Livulu'),
    ('Mbanza-Lemba'),
    ('Funa'),
    ('Industriel'),
    ('Résidentiel'),
    ('Commercial');

CREATE TABLE ref_avenue (
    id SERIAL PRIMARY KEY,
    libelle TEXT NOT NULL
);

INSERT INTO ref_avenue (libelle) VALUES
    ('Avenue de la Libération'),
    ('Avenue Lumumba'),
    ('Avenue Kasavubu'),
    ('Avenue du Commerce'),
    ('Avenue de la Paix'),
    ('Avenue des Huileries'),
    ('Avenue Colonel Mondjiba'),
    ('Avenue de l''Université'),
    ('Avenue Sendwe'),
    ('Avenue Kasa-Vubu');

-- Main Tables
-- =============================================

CREATE TABLE contribuables (
    id SERIAL PRIMARY KEY,
    nif TEXT,
    type_nif TEXT,
    type_contribuable TEXT NOT NULL,
    nom TEXT,
    post_nom TEXT,
    prenom TEXT,
    raison_sociale TEXT,
    telephone1 TEXT NOT NULL,
    telephone2 TEXT,
    email TEXT,
    commune_id INTEGER REFERENCES ref_commune(id),
    quartier_id INTEGER REFERENCES ref_quartier(id),
    avenue_id INTEGER REFERENCES ref_avenue(id),
    rue TEXT,
    numero_parcelle TEXT,
    origine_fiche TEXT NOT NULL,
    activite_id INTEGER REFERENCES ref_type_activite(id),
    zone_id INTEGER REFERENCES ref_zone_type(id),
    statut INTEGER,
    gps_latitude DOUBLE PRECISION,
    gps_longitude DOUBLE PRECISION,
    piece_identite_url TEXT,
    date_inscription TIMESTAMP,
    created_at TIMESTAMP,
    cree_par TEXT NOT NULL,
    date_maj TIMESTAMP,
    maj_par TEXT,
    forme_juridique TEXT,
    numero_rccm TEXT,
    updated_at TIMESTAMP
);

CREATE TABLE parcelles (
    id SERIAL PRIMARY KEY,
    code_parcelle TEXT,
    reference_cadastrale TEXT,
    commune TEXT,
    quartier TEXT,
    rue_avenue TEXT,
    numero_adresse TEXT,
    commune_id INTEGER REFERENCES ref_commune(id),
    quartier_id INTEGER REFERENCES ref_quartier(id),
    avenue_id INTEGER REFERENCES ref_avenue(id),
    rue TEXT,
    numero_parcelle TEXT,
    superficie_m2 DOUBLE PRECISION,
    gps_lat DOUBLE PRECISION,
    gps_lon DOUBLE PRECISION,
    statut_parcelle TEXT NOT NULL,
    date_creation TIMESTAMP,
    date_mise_a_jour TIMESTAMP,
    source_donnee TEXT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE personnes (
    id SERIAL PRIMARY KEY,
    type_personne TEXT NOT NULL,
    nom_raison_sociale TEXT,
    nif TEXT,
    contact TEXT,
    adresse_postale TEXT,
    parcelle_id INTEGER UNIQUE REFERENCES parcelles(id) ON DELETE CASCADE,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE batiments (
    id SERIAL PRIMARY KEY,
    parcelle_id INTEGER REFERENCES parcelles(id) ON DELETE CASCADE,
    type_batiment TEXT NOT NULL,
    nombre_etages INTEGER,
    annee_construction INTEGER,
    surface_batie_m2 DOUBLE PRECISION,
    usage_principal TEXT NOT NULL,
    statut_batiment TEXT NOT NULL,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
