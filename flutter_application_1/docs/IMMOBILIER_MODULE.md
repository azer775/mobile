# Module Immobilier - Documentation

> **For AI Agents:** This document describes the Immobilier module in detail. Follow these patterns when modifying or extending this module.

---

## Table of Contents

1. [Module Overview](#module-overview)
2. [Architecture](#architecture)
3. [Entity Relationships](#entity-relationships)
4. [File Inventory](#file-inventory)
5. [Entity Models](#entity-models)
6. [Enums](#enums)
7. [Local Datasources](#local-datasources)
8. [Presentation Layer](#presentation-layer)
9. [Database Schema](#database-schema)
10. [Reference Tables](#reference-tables)
11. [Naming Conventions](#naming-conventions)
12. [Notes for AI Agents](#notes-for-ai-agents)

---

## Module Overview

The Immobilier module manages **real-estate property** data: land parcels (parcelles), their owners (personnes), and buildings on the parcels (bâtiments). Data entry uses a **3-step wizard** flow to capture all related entities in a single guided process.

### Core Concepts

| Concept | Description |
|---------|-------------|
| **Parcelle** | A land parcel with cadastral reference, address (commune/quartier/avenue), GPS coordinates, and surface area |
| **Personne** | The owner of a parcelle — can be *physique* (individual) or *morale* (company) |
| **Bâtiment** | A building on a parcelle — type, floors, construction year, usage, and status |

---

## Architecture

The module follows the same **3-layer architecture** as the rest of the project:

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  ImmobilierPage (list) → ImmobilierWizard (3-step form)     │
│  Sub-forms: ParcelleForm, PersonneForm, BatimentListStep    │
│  Widgets: ParcelleListTile, ParcelleDetailsSheet            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       DATA LAYER                             │
│  Entities: ParcelleEntity, PersonneEntity, BatimentEntity   │
│  Enums: StatutParcelle, TypeBatiment, UsagePrincipal, etc.  │
│  Datasources: ParcelleLocal, PersonneLocal, BatimentLocal   │
│  Reference: RefCommuneEntity, RefQuartierEntity, RefAvenue  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       CORE LAYER                             │
│  DatabaseHelper (SQLite), Validators, SuccessPopup          │
└─────────────────────────────────────────────────────────────┘
```

---

## Entity Relationships

```
┌──────────────┐       1:1       ┌──────────────┐
│   Parcelle   │────────────────▶│   Personne   │
│              │                 │   (owner)    │
└──────┬───────┘                 └──────────────┘
       │
       │  1:N
       ▼
┌──────────────┐
│  Bâtiment    │  (0 or more buildings per parcelle)
│  Bâtiment    │
│  ...         │
└──────────────┘
```

- **Parcelle ↔ Personne**: One-to-one. `personnes.parcelle_id` is `UNIQUE` and has `ON DELETE CASCADE`.
- **Parcelle ↔ Bâtiment**: One-to-many. `batiments.parcelle_id` has `ON DELETE CASCADE`.

---

## File Inventory

### Data Layer

| File | Purpose |
|------|---------|
| `data/models/entities/parcelle_entity.dart` | Parcelle entity model |
| `data/models/entities/batiment_entity.dart` | Bâtiment entity model |
| `data/models/entities/personne_entity.dart` | Personne entity model |
| `data/models/entities/ref_commune_entity.dart` | Commune reference entity |
| `data/models/entities/ref_quartier_entity.dart` | Quartier reference entity |
| `data/models/entities/ref_avenue_entity.dart` | Avenue reference entity |
| `data/models/enums/parcelle_enums.dart` | All enums for this module (5 enums) |
| `data/datasources/local/parcelle_local_datasource.dart` | CRUD + search + details for parcelles |
| `data/datasources/local/batiment_local_datasource.dart` | CRUD + parcelle-scoped queries for bâtiments |
| `data/datasources/local/personne_local_datasource.dart` | CRUD + parcelle-scoped queries for personnes |
| `data/datasources/local/ref_commune_local_datasource.dart` | Read-only for communes |
| `data/datasources/local/ref_quartier_local_datasource.dart` | Read-only for quartiers |
| `data/datasources/local/ref_avenue_local_datasource.dart` | Read-only for avenues |

### Presentation Layer

| File | Purpose |
|------|---------|
| `presentation/pages/immobilier_page.dart` | List page with search, filter by status, FAB |
| `presentation/forms/immobilier_wizard.dart` | 3-step Stepper (Parcelle → Personne → Bâtiments) |
| `presentation/forms/parcelle_form.dart` | Step 1: Parcelle form fields |
| `presentation/forms/personne_form.dart` | Step 2: Personne (owner) form fields |
| `presentation/forms/batiment_form.dart` | Single bâtiment dialog form |
| `presentation/forms/batiment_list_step.dart` | Step 3: List of bâtiments with add/edit/delete |
| `presentation/widgets/parcelle_list_tile.dart` | List item widget showing parcelle summary |
| `presentation/widgets/parcelle_details_sheet.dart` | Bottom sheet with full parcelle + personne + bâtiments |

### Routing

Route constant: `AppRoutes.immobilier = '/immobilier'`  
Defined in: `presentation/routes/app_routes.dart`

---

## Entity Models

### ParcelleEntity (`parcelle_entity.dart`)

Extends `BaseEntity`. Table: `parcelles`.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `codeParcelle` | `String?` | No | Parcel code |
| `referenceCadastrale` | `String?` | No | Cadastral reference |
| `commune` | `String?` | No | Commune name |
| `quartier` | `String?` | No | Quartier name |
| `rueAvenue` | `String?` | No | Street/avenue |
| `numeroAdresse` | `String?` | No | Address number |
| `superficieM2` | `double?` | No | Surface area in m² |
| `gpsLat` | `double?` | No | GPS latitude |
| `gpsLon` | `double?` | No | GPS longitude |
| `statutParcelle` | `StatutParcelle` | **Yes** | Parcel status enum |
| `dateCreation` | `DateTime?` | No | Creation date |
| `dateMiseAJour` | `DateTime?` | No | Last update date |
| `sourceDonnee` | `String?` | No | Data source |

**Helper getters:**
- `mainAddress` → computed full address string
- `hasGps` → `true` if both lat/lon are set
- `copyWith(...)` → immutable update method

---

### PersonneEntity (`personne_entity.dart`)

Extends `BaseEntity`. Table: `personnes`.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `typePersonne` | `TypePersonne` | **Yes** | physique / morale |
| `nomRaisonSociale` | `String?` | No | Name or company name |
| `nif` | `String?` | No | Tax ID (NIF) |
| `contact` | `String?` | No | Phone/contact |
| `adressePostale` | `String?` | No | Postal address |
| `parcelleId` | `int?` | No | FK → `parcelles.id` |

**Helper getters:**
- `displayName` → name or fallback text
- `copyWith(...)`

---

### BatimentEntity (`batiment_entity.dart`)

Extends `BaseEntity`. Table: `batiments`.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `parcelleId` | `int?` | No | FK → `parcelles.id` |
| `typeBatiment` | `TypeBatiment` | **Yes** | Building type enum |
| `nombreEtages` | `int?` | No | Number of floors |
| `anneeConstruction` | `int?` | No | Year of construction |
| `surfaceBatieM2` | `double?` | No | Built surface area in m² |
| `usagePrincipal` | `UsagePrincipal` | **Yes** | Primary usage enum |
| `statutBatiment` | `StatutBatiment` | **Yes** | Building status enum |

**Helper getters:**
- `displayInfo` → formatted string: "type – usage (N étages)"
- `copyWith(...)`

---

## Enums

All enums are defined in `data/models/enums/parcelle_enums.dart`.

### StatutParcelle
| Value | String |
|-------|--------|
| `active` | `active` |
| `fusionnee` | `fusionnée` |
| `subdivisee` | `subdivisée` |
| `archivee` | `archivée` |

### TypeBatiment
| Value | String |
|-------|--------|
| `maison` | `maison` |
| `immeuble` | `immeuble` |
| `entrepot` | `entrepôt` |
| `commerce` | `commerce` |
| `bureau` | `bureau` |
| `autre` | `autre` |

### UsagePrincipal
| Value | String |
|-------|--------|
| `residentiel` | `résidentiel` |
| `commercial` | `commercial` |
| `mixte` | `mixte` |
| `autre` | `autre` |

### StatutBatiment
| Value | String |
|-------|--------|
| `enService` | `en service` |
| `enRuine` | `en ruine` |
| `enChantier` | `en chantier` |
| `autre` | `autre` |

### TypePersonne
| Value | String |
|-------|--------|
| `physique` | `physique` |
| `morale` | `morale` |

> **Pattern:** Each enum has a `value` field, a `fromString()` static constructor, and uses lowercase comparison. Default values are used when the string is `null` or unrecognized.

---

## Local Datasources

### ParcelleLocalDatasource

| Method | Returns | Description |
|--------|---------|-------------|
| `insertParcelle(ParcelleEntity)` | `Future<int>` | Insert, returns new ID |
| `getAllParcelles()` | `Future<List<ParcelleEntity>>` | All parcelles, ordered by `created_at DESC` |
| `getParcelleById(int)` | `Future<ParcelleEntity?>` | Single parcelle by ID |
| `searchParcelles(String)` | `Future<List<ParcelleEntity>>` | Search by code, commune, quartier, avenue, ref cadastrale |
| `updateParcelle(ParcelleEntity)` | `Future<int>` | Update existing |
| `deleteParcelle(int)` | `Future<int>` | Delete (cascades to personnes & bâtiments) |
| `countParcelles()` | `Future<int>` | Total count |
| `getParcelleWithDetails(int)` | `Future<Map?>` | Returns `{parcelle, personne, batiments}` |

### BatimentLocalDatasource

| Method | Returns | Description |
|--------|---------|-------------|
| `insertBatiment(BatimentEntity)` | `Future<int>` | Insert single |
| `insertBatiments(List<BatimentEntity>)` | `Future<void>` | Batch insert |
| `getAllBatiments()` | `Future<List<BatimentEntity>>` | All bâtiments |
| `getBatimentById(int)` | `Future<BatimentEntity?>` | Single by ID |
| `getBatimentsByParcelleId(int)` | `Future<List<BatimentEntity>>` | All for a parcelle |
| `updateBatiment(BatimentEntity)` | `Future<int>` | Update existing |
| `deleteBatiment(int)` | `Future<int>` | Delete single |
| `deleteBatimentsByParcelleId(int)` | `Future<int>` | Delete all for a parcelle |
| `countBatimentsByParcelleId(int)` | `Future<int>` | Count for a parcelle |

### PersonneLocalDatasource

| Method | Returns | Description |
|--------|---------|-------------|
| `insertPersonne(PersonneEntity)` | `Future<int>` | Insert single |
| `getAllPersonnes()` | `Future<List<PersonneEntity>>` | All personnes |
| `getPersonneById(int)` | `Future<PersonneEntity?>` | Single by ID |
| `getPersonneByParcelleId(int)` | `Future<PersonneEntity?>` | Owner of a parcelle (1:1) |
| `updatePersonne(PersonneEntity)` | `Future<int>` | Update existing |
| `deletePersonne(int)` | `Future<int>` | Delete single |
| `deletePersonneByParcelleId(int)` | `Future<int>` | Delete by parcelle FK |
| `searchPersonnes(String)` | `Future<List<PersonneEntity>>` | Search by name, NIF, contact |

---

## Presentation Layer

### ImmobilierPage (`immobilier_page.dart`)

The main list page for parcelles.

**Features:**
- Loads all parcelles with associated personne names and bâtiment counts
- **Search bar** filtering by code, commune, quartier, ref cadastrale
- **Filter chips** for `StatutParcelle` values (Tous, active, fusionnée, subdivisée, archivée)
- **FAB** "Nouvelle Parcelle" → opens `ImmobilierWizard` in create mode
- **Pull-to-refresh**
- **Empty state** with icon + message
- **Results count** displayed above list
- Tap on item → `ParcelleDetailsSheet` bottom sheet
- Edit → reopens `ImmobilierWizard` with `parcelleId`
- Delete → confirmation dialog with cascade warning

---

### ImmobilierWizard (`immobilier_wizard.dart`)

A **3-step horizontal Stepper** for creating or editing a complete parcelle record.

```
Step 1: Parcelle        Step 2: Propriétaire      Step 3: Bâtiments
(ParcelleForm)          (PersonneForm)             (BatimentListStep)
```

**Key Behavior:**
- **Create mode**: `parcelleId` is `null` → all forms start empty
- **Edit mode**: `parcelleId` is provided → loads existing data via `getParcelleWithDetails()`
- Step validation: cannot advance without valid current step
- Step tapping: validates current step before jumping
- Saves current step data when going back or switching
- **Save logic** (`_saveAllData`):
  1. Insert or update the `Parcelle`
  2. Insert or update the `Personne` (linked via `parcelle_id`)
  3. Diff bâtiments: delete removed ones, insert new ones, update existing ones
- Uses `SuccessPopup` for success messages

**Sub-form communication:** via `GlobalKey<FormState>` pattern:
- `_parcelleFormKey.currentState!.validate()` → bool
- `_parcelleFormKey.currentState!.getData()` → `ParcelleEntity`

---

### Sub-forms

#### ParcelleForm (`parcelle_form.dart`)
- Fields for all `ParcelleEntity` attributes
- Uses dropdown references for commune, quartier, avenue
- GPS coordinate capture
- Can be embedded (no AppBar) via `showAppBar: false`
- Exposes `validate()` and `getData()` methods via State

#### PersonneForm (`personne_form.dart`)
- Fields for `TypePersonne` (dropdown), name, NIF, contact, postal address
- Can be embedded via `showAppBar: false`
- Exposes `validate()` and `getData()` methods via State

#### BatimentForm (`batiment_form.dart`)
- Single bâtiment dialog form
- Dropdowns for `TypeBatiment`, `UsagePrincipal`, `StatutBatiment`
- Fields for floors, construction year, built surface

#### BatimentListStep (`batiment_list_step.dart`)
- Displays a list of bâtiments (0 or more)
- Add button opens `BatimentForm` dialog
- Each item can be edited or deleted
- Exposes `getData()` → `List<BatimentEntity>`

---

### Widgets

#### ParcelleListTile (`parcelle_list_tile.dart`)
- Displays parcelle summary in the list
- Shows: commune/quartier, status badge, bâtiment count, owner name

#### ParcelleDetailsSheet (`parcelle_details_sheet.dart`)
- Modal bottom sheet with full details
- Sections: Parcelle info, Propriétaire info, Bâtiments list
- Action buttons: Edit, Delete

---

## Database Schema

### `parcelles` (added in migration v7)

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT |
| `code_parcelle` | TEXT | |
| `reference_cadastrale` | TEXT | |
| `commune` | TEXT | |
| `quartier` | TEXT | |
| `rue_avenue` | TEXT | |
| `numero_adresse` | TEXT | |
| `superficie_m2` | REAL | |
| `gps_lat` | REAL | |
| `gps_lon` | REAL | |
| `statut_parcelle` | TEXT | NOT NULL |
| `date_creation` | TEXT | ISO8601 |
| `date_mise_a_jour` | TEXT | ISO8601 |
| `source_donnee` | TEXT | |
| `created_at` | TEXT | ISO8601 |
| `updated_at` | TEXT | ISO8601 |

### `personnes` (added in migration v7)

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT |
| `type_personne` | TEXT | NOT NULL |
| `nom_raison_sociale` | TEXT | |
| `nif` | TEXT | |
| `contact` | TEXT | |
| `adresse_postale` | TEXT | |
| `parcelle_id` | INTEGER | UNIQUE, FK → `parcelles(id)` ON DELETE CASCADE |
| `created_at` | TEXT | ISO8601 |
| `updated_at` | TEXT | ISO8601 |

### `batiments` (added in migration v7)

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT |
| `parcelle_id` | INTEGER | FK → `parcelles(id)` ON DELETE CASCADE |
| `type_batiment` | TEXT | NOT NULL |
| `nombre_etages` | INTEGER | |
| `annee_construction` | INTEGER | |
| `surface_batie_m2` | REAL | |
| `usage_principal` | TEXT | NOT NULL |
| `statut_batiment` | TEXT | NOT NULL |
| `created_at` | TEXT | ISO8601 |
| `updated_at` | TEXT | ISO8601 |

---

## Reference Tables

Used by the parcelle form for address dropdowns. Added in migration v10.

### `ref_commune`

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT |
| `libelle` | TEXT | NOT NULL |

**Initial data (24 Kinshasa communes):** Bandalungwa, Barumbu, Bumbu, Gombe, Kalamu, Kasa-Vubu, Kimbanseke, Kinshasa, Kintambo, Kisenso, Lemba, Limete, Lingwala, Makala, Maluku, Masina, Matete, Mont-Ngafula, Ndjili, Ngaba, Ngaliema, Ngiri-Ngiri, Nsele, Selembao

### `ref_quartier`

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT |
| `libelle` | TEXT | NOT NULL |

**Initial data (10 quartiers):** Centre-ville, Matonge, Yolo, Righini, Livulu, Mbanza-Lemba, Funa, Industriel, Résidentiel, Commercial

### `ref_avenue`

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT |
| `libelle` | TEXT | NOT NULL |

**Initial data (10 avenues):** Avenue de la Libération, Avenue Lumumba, Avenue Kasavubu, Avenue du Commerce, Avenue de la Paix, Avenue des Huileries, Avenue Colonel Mondjiba, Avenue de l'Université, Avenue Sendwe, Avenue Kasa-Vubu

> **Note:** These are read-only lookup tables. Entity classes: `RefCommuneEntity`, `RefQuartierEntity`, `RefAvenueEntity`. Datasources: `RefCommuneLocalDatasource`, `RefQuartierLocalDatasource`, `RefAvenueLocalDatasource`.

---

## Naming Conventions

### Files (Immobilier module)
- Entities: `parcelle_entity.dart`, `batiment_entity.dart`, `personne_entity.dart`
- Enums: `parcelle_enums.dart` (shared across all three entities)
- Datasources: `parcelle_local_datasource.dart`, `batiment_local_datasource.dart`, `personne_local_datasource.dart`
- Page: `immobilier_page.dart` (the module-level page, NOT `parcelles_page.dart`)
- Wizard: `immobilier_wizard.dart`
- Sub-forms: `parcelle_form.dart`, `personne_form.dart`, `batiment_form.dart`, `batiment_list_step.dart`
- Widgets: `parcelle_list_tile.dart`, `parcelle_details_sheet.dart`

### Classes
- Entities: `ParcelleEntity`, `BatimentEntity`, `PersonneEntity`
- Datasources: `ParcelleLocalDatasource`, `BatimentLocalDatasource`, `PersonneLocalDatasource`
- Page: `ImmobilierPage`
- Wizard: `ImmobilierWizard`

### Database
- Table names: `parcelles`, `batiments`, `personnes`, `ref_commune`, `ref_quartier`, `ref_avenue`
- Column names: `snake_case` (e.g., `parcelle_id`, `type_batiment`, `nom_raison_sociale`)

### Route
- Path: `/immobilier`
- Constant: `AppRoutes.immobilier`

---

## Notes for AI Agents

1. **The immobilier module uses a wizard pattern**, not individual CRUD pages — all three entities are saved together.
2. **Parcelle is the root entity**: Personne and Bâtiment both reference it via `parcelle_id`.
3. **Cascading deletes**: Deleting a parcelle automatically deletes its associated personne and bâtiments (enforced via `ON DELETE CASCADE`).
4. **Enums are shared**: All 5 enums live in `parcelle_enums.dart`, even those used by `BatimentEntity` and `PersonneEntity`.
5. **Sub-forms expose State**: Use `GlobalKey<[Form]State>` to call `validate()` and `getData()` from the wizard.
6. **Edit mode** loads existing data via `ParcelleLocalDatasource.getParcelleWithDetails()` which returns parcelle + personne + bâtiments in a `Map`.
7. **Bâtiment diffing on save**: The wizard compares old vs new bâtiment IDs to decide what to insert, update, or delete.
8. **Reference tables** (commune, quartier, avenue) are used as dropdown options in the parcelle form.
9. **Current database version**: **10** (defined in `db_constants.dart`). Parcelle tables were added in v7, ref tables in v10.
10. **Always handle async gaps** with `if (mounted)` checks — the existing code follows this pattern consistently.
