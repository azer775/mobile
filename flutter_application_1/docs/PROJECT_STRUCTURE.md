# Flutter Application - Project Documentation

> **For AI Agents:** This document provides a comprehensive guide to the project structure, patterns, and conventions used. Follow these patterns when making changes or adding new features.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Folder Structure](#folder-structure)
4. [CRUD Implementation Pattern](#crud-implementation-pattern)
5. [Adding a New Entity (Step-by-Step)](#adding-a-new-entity-step-by-step)
6. [Key Files Reference](#key-files-reference)
7. [Naming Conventions](#naming-conventions)
8. [Database Schema](#database-schema)

---

## Project Overview

This is a Flutter application built with a **clean architecture** approach. The app currently manages **Contribuables** (taxpayers) with full CRUD operations, authentication, and local SQLite storage.

### Tech Stack
- **Flutter** - UI Framework
- **SQLite (sqflite)** - Local database
- **Provider/Service pattern** - State management
- **Material Design 3** - UI components

---

## Architecture

The project follows a **3-layer architecture**:

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  (pages, forms, widgets, routes)                            │
│  - UI components                                             │
│  - User interaction                                          │
│  - Navigation                                                │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       DATA LAYER                             │
│  (models, datasources, repositories)                        │
│  - Entities (database models)                               │
│  - DTOs (API models)                                        │
│  - Local/Remote datasources                                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       CORE LAYER                             │
│  (constants, services, utils, theme, errors)                │
│  - Shared utilities                                          │
│  - App-wide services                                         │
│  - Theme configuration                                       │
└─────────────────────────────────────────────────────────────┘
```

---

## Folder Structure

```
lib/
├── main.dart                          # App entry point
├── core/                              # Shared/core functionality
│   ├── constants/
│   │   ├── api_constants.dart         # API URLs, endpoints
│   │   ├── app_constants.dart         # App-wide constants
│   │   └── db_constants.dart          # Database name, version
│   ├── errors/                        # Error handling classes
│   ├── services/
│   │   ├── auth_service.dart          # Authentication logic
│   │   └── secret_credentials_service.dart
│   ├── theme/
│   │   └── app_theme.dart             # ThemeData configuration
│   └── utils/
│       ├── camera_service.dart        # Camera/photo utilities
│       ├── location_service.dart      # GPS utilities
│       ├── success_popup.dart         # Success dialogs
│       └── validators.dart            # Form validators
│
├── data/                              # Data layer
│   ├── datasources/
│   │   ├── local/
│   │   │   ├── database_helper.dart   # SQLite singleton helper
│   │   │   └── [entity]_local_datasource.dart
│   │   └── remote/
│   │       └── api_client.dart        # HTTP client
│   ├── models/
│   │   ├── base/
│   │   │   ├── base_entity.dart       # Abstract entity class
│   │   │   └── base_dto.dart          # Abstract DTO class
│   │   ├── entities/
│   │   │   └── [entity]_entity.dart   # Database models
│   │   ├── dtos/
│   │   │   └── [entity]_dto.dart      # API models (optional)
│   │   └── enums/
│   │       └── [entity]_enums.dart    # Related enums
│   └── repositories/                  # (Optional) Repository pattern
│
└── presentation/                      # UI layer
    ├── forms/
    │   └── [entity]_form.dart         # Create/Edit forms
    ├── pages/
    │   ├── home_page.dart             # Main navigation
    │   ├── login_page.dart            # Authentication
    │   └── [entity]s_page.dart        # List page (plural)
    ├── routes/
    │   ├── app_routes.dart            # Route definitions
    │   └── routing_guide.dart         # Navigation guide
    └── widgets/
        ├── common_widgets.dart        # Reusable widgets
        ├── [entity]_list_tile.dart    # List item widget
        └── [entity]_details_sheet.dart # Details view widget
```

---

## CRUD Implementation Pattern

Each entity follows a consistent pattern across all layers:

### 1. Entity Model (`data/models/entities/[entity]_entity.dart`)

```dart
import '../base/base_entity.dart';

class ExampleEntity extends BaseEntity {
  String name;
  String? description;
  // ... other fields

  ExampleEntity({
    super.id,
    required this.name,
    this.description,
    super.createdAt,
    super.updatedAt,
  });

  @override
  String get tableName => 'examples';  // Database table name

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory ExampleEntity.fromMap(Map<String, dynamic> map) {
    return ExampleEntity(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}
```

### 2. Enums (`data/models/enums/[entity]_enums.dart`)

```dart
enum ExampleStatus {
  active('ACTIVE'),
  inactive('INACTIVE');

  final String value;
  const ExampleStatus(this.value);

  static ExampleStatus fromString(String value) {
    return ExampleStatus.values.firstWhere(
      (e) => e.value == value.toUpperCase(),
      orElse: () => ExampleStatus.active,
    );
  }

  String get displayName {
    switch (this) {
      case ExampleStatus.active:
        return 'Active';
      case ExampleStatus.inactive:
        return 'Inactive';
    }
  }
}
```

### 3. Local Datasource (`data/datasources/local/[entity]_local_datasource.dart`)

```dart
import 'database_helper.dart';
import '../../models/entities/example_entity.dart';

class ExampleLocalDatasource {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// CREATE
  Future<int> insertExample(ExampleEntity example) async {
    final map = example.toMap();
    map.remove('id');
    return await _dbHelper.insert('examples', map);
  }

  /// READ (all)
  Future<List<ExampleEntity>> getAllExamples() async {
    final maps = await _dbHelper.queryAll('examples');
    return maps.map((map) => ExampleEntity.fromMap(map)).toList();
  }

  /// READ (by id)
  Future<ExampleEntity?> getExampleById(int id) async {
    final maps = await _dbHelper.query(
      'examples',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ExampleEntity.fromMap(maps.first);
  }

  /// UPDATE
  Future<int> updateExample(ExampleEntity example) async {
    return await _dbHelper.update(
      'examples',
      example.toMap(),
      where: 'id = ?',
      whereArgs: [example.id],
    );
  }

  /// DELETE
  Future<int> deleteExample(int id) async {
    return await _dbHelper.delete(
      'examples',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
```

### 4. Database Table (in `database_helper.dart`)

Add table creation in `_onCreate` method:

```dart
await db.execute('''
  CREATE TABLE examples (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    description TEXT,
    created_at TEXT,
    updated_at TEXT
  )
''');
```

### 5. List Page (`presentation/pages/[entity]s_page.dart`)

Structure:
- StatefulWidget with list state
- Load data in `initState`
- Search/filter functionality
- FAB for adding new items
- Pull-to-refresh
- Empty state UI

### 6. Form Page (`presentation/forms/[entity]_form.dart`)

Structure:
- StatefulWidget with form key
- TextEditingControllers for each field
- Validation using `validators.dart`
- Save callback pattern: `onSave: (entity) async { ... }`

### 7. Widgets (`presentation/widgets/`)

- `[entity]_list_tile.dart` - List item with avatar, title, subtitle
- `[entity]_details_sheet.dart` - Bottom sheet with full details

### 8. Routes (`presentation/routes/app_routes.dart`)

```dart
static const String examples = '/examples';

static Map<String, WidgetBuilder> get routes {
  return {
    // ... existing routes
    examples: (context) => const ExamplesPage(),
  };
}
```

---

## Adding a New Entity (Step-by-Step)

### Step 1: Create the Entity Model

**File:** `lib/data/models/entities/[new_entity]_entity.dart`

1. Import `base_entity.dart`
2. Extend `BaseEntity`
3. Define fields with types
4. Implement `tableName` getter
5. Implement `toMap()` method
6. Implement `fromMap()` factory constructor

### Step 2: Create Enums (if needed)

**File:** `lib/data/models/enums/[new_entity]_enums.dart`

1. Define enums with string values
2. Add `fromString()` static method
3. Add `displayName` getter for UI

### Step 3: Update Database Helper

**File:** `lib/data/datasources/local/database_helper.dart`

1. Add CREATE TABLE in `_onCreate()`
2. Add migration in `_onUpgrade()` if updating existing DB
3. Increment `databaseVersion` in `db_constants.dart`

### Step 4: Create Local Datasource

**File:** `lib/data/datasources/local/[new_entity]_local_datasource.dart`

1. Implement CRUD methods:
   - `insert[Entity]()`
   - `getAll[Entities]()`
   - `get[Entity]ById()`
   - `update[Entity]()`
   - `delete[Entity]()`

### Step 5: Create Form Widget

**File:** `lib/presentation/forms/[new_entity]_form.dart`

1. Create StatefulWidget
2. Add form key and controllers
3. Build form fields with validation
4. Handle save with callback

### Step 6: Create List Page

**File:** `lib/presentation/pages/[new_entity]s_page.dart`

1. Create StatefulWidget
2. Load data from datasource
3. Implement search/filter
4. Add navigation to form
5. Handle delete with confirmation

### Step 7: Create Supporting Widgets

**Files:**
- `lib/presentation/widgets/[new_entity]_list_tile.dart`
- `lib/presentation/widgets/[new_entity]_details_sheet.dart`

### Step 8: Add Routes

**File:** `lib/presentation/routes/app_routes.dart`

1. Add route constant
2. Add to routes map
3. Import the page

### Step 9: Add Navigation (optional)

**File:** `lib/presentation/pages/home_page.dart`

Add button to navigate to new entity list.

---

## Key Files Reference

| File | Purpose |
|------|---------|
| `main.dart` | App entry, MaterialApp configuration |
| `app_routes.dart` | All route definitions |
| `database_helper.dart` | SQLite singleton, table creation |
| `db_constants.dart` | Database name and version |
| `base_entity.dart` | Abstract class all entities extend |
| `auth_service.dart` | Authentication state management |
| `validators.dart` | Form field validators |
| `success_popup.dart` | Success dialog utilities |

---

## Naming Conventions

### Files
- Entities: `[name]_entity.dart` (singular)
- Enums: `[name]_enums.dart`
- Datasources: `[name]_local_datasource.dart`
- Pages: `[name]s_page.dart` (plural)
- Forms: `[name]_form.dart` (singular)
- Widgets: `[name]_list_tile.dart`, `[name]_details_sheet.dart`

### Classes
- Entities: `[Name]Entity` (PascalCase)
- Datasources: `[Name]LocalDatasource`
- Pages: `[Name]sPage` (plural)
- Forms: `[Name]Form`

### Database
- Table names: `snake_case` (plural): `contribuables`, `users`
- Column names: `snake_case`: `created_at`, `type_nif`

### Routes
- Path: `/[name]s` (plural, lowercase): `/contribuables`
- Constant: `static const String [name]s = '/[name]s'`

---

## Database Schema

### Current Tables

#### `ref_type_activite` (Reference Table)
| Column | Type | Constraints |
|--------|------|-------------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT |
| libelle | TEXT | NOT NULL |

> **Note:** This is a reference/lookup table populated via SQL. No CRUD forms needed.
> Initial data includes: Commerce général, Agriculture, Artisanat, Services, Transport, Restauration, Hôtellerie, Construction, Industrie, Santé, Éducation, Télécommunications, Banque et Finance, Immobilier, Autre

#### `ref_zone_type` (Reference Table)
| Column | Type | Constraints |
|--------|------|-------------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT |
| libelle | TEXT | NOT NULL |

> **Note:** This is a reference/lookup table populated via SQL. No CRUD forms needed.
> Initial data includes: Zone Urbaine, Zone Périurbaine, Zone Rurale, Zone Industrielle, Zone Commerciale, Zone Résidentielle, Zone Mixte

#### `contribuables`
| Column | Type | Constraints |
|--------|------|-------------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT |
| nif | TEXT | |
| type_nif | TEXT | |
| type_contribuable | TEXT | NOT NULL |
| nom | TEXT | |
| post_nom | TEXT | |
| prenom | TEXT | |
| raison_sociale | TEXT | |
| telephone1 | TEXT | NOT NULL |
| telephone2 | TEXT | |
| email | TEXT | |
| adresse | TEXT | NOT NULL |
| origine_fiche | TEXT | NOT NULL |
| activite_id | INTEGER | FK → ref_type_activite(id) |
| zone_id | INTEGER | FK → ref_zone_type(id) |
| statut | INTEGER | |
| gps_latitude | REAL | |
| gps_longitude | REAL | |
| piece_identite_url | TEXT | JSON array |
| date_inscription | TEXT | ISO8601 |
| created_at | TEXT | ISO8601 |
| cree_par | TEXT | NOT NULL |
| date_maj | TEXT | ISO8601 |
| maj_par | TEXT | |
| updated_at | TEXT | ISO8601 |

### Database Versioning

Current version: **5** (defined in `db_constants.dart`)

When adding new tables or modifying schema:
1. Increment `databaseVersion`
2. Add migration logic in `_onUpgrade()`
3. Use `CREATE TABLE IF NOT EXISTS` for safety

---

## Quick Commands

```bash
# Run the app
flutter run

# Analyze code
flutter analyze

# Get dependencies
flutter pub get

# Build APK
flutter build apk

# Build iOS
flutter build ios
```

---

## Notes for AI Agents

1. **Always extend BaseEntity** for new database models
2. **Always update database_helper.dart** when adding tables
3. **Always increment database version** when modifying schema
4. **Follow the existing patterns** - look at `contribuable_*` files as reference
5. **Use the validators** from `core/utils/validators.dart`
6. **Use SuccessPopup** for consistent success messages
7. **Implement search/filter** in list pages for better UX
8. **Keep widgets small** - extract to separate files when > 100 lines
9. **Use enums with string values** for database compatibility
10. **Always handle async gaps** with `if (mounted)` checks
