import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../../core/constants/db_constants.dart';
import '../../../core/utils/camera_service.dart';

/// Database helper for SQLite operations
class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._();

  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, DbConstants.databaseName);

    return await openDatabase(
      path,
      version: DbConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create ref_type_activite reference table
    await db.execute('''
      CREATE TABLE ref_type_activite (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        libelle TEXT NOT NULL
      )
    ''');

    // Populate ref_type_activite with initial data
    await db.execute('''
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
      ('Autre')
    ''');

    // Create ref_zone_type reference table
    await db.execute('''
      CREATE TABLE ref_zone_type (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        libelle TEXT NOT NULL
      )
    ''');

    // Populate ref_zone_type with initial data
    await db.execute('''
      INSERT INTO ref_zone_type (libelle) VALUES
      ('Zone urbaine'),
      ('Zone périurbaine'),
      ('Zone rurale'),
      ('Zone industrielle'),
      ('Zone commerciale'),
      ('Zone résidentielle'),
      ('Zone mixte')
    ''');

    // Create ref_commune reference table
    await db.execute('''
      CREATE TABLE ref_commune (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        libelle TEXT NOT NULL
      )
    ''');

    // Populate ref_commune with Kinshasa communes
    await db.execute('''
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
      ('Selembao')
    ''');

    // Create ref_quartier reference table
    await db.execute('''
      CREATE TABLE ref_quartier (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        libelle TEXT NOT NULL
      )
    ''');

    // Populate ref_quartier with sample quartiers
    await db.execute('''
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
      ('Commercial')
    ''');

    // Create ref_avenue reference table
    await db.execute('''
      CREATE TABLE ref_avenue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        libelle TEXT NOT NULL
      )
    ''');

    // Populate ref_avenue with sample avenues
    await db.execute('''
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
      ('Avenue Kasa-Vubu')
    ''');

    // Create contribuables table
    await db.execute('''
      CREATE TABLE contribuables (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
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
        commune_id INTEGER,
        quartier_id INTEGER,
        avenue_id INTEGER,
        rue TEXT,
        numero_parcelle TEXT,
        origine_fiche TEXT NOT NULL,
        activite_id INTEGER,
        zone_id INTEGER,
        statut INTEGER,
        gps_latitude REAL,
        gps_longitude REAL,
        piece_identite_url TEXT,
        date_inscription TEXT,
        created_at TEXT,
        cree_par TEXT NOT NULL,
        date_maj TEXT,
        maj_par TEXT,
        forme_juridique TEXT,
        numero_rccm TEXT,
        updated_at TEXT,
        FOREIGN KEY (activite_id) REFERENCES ref_type_activite (id),
        FOREIGN KEY (zone_id) REFERENCES ref_zone_type (id),
        FOREIGN KEY (commune_id) REFERENCES ref_commune (id),
        FOREIGN KEY (quartier_id) REFERENCES ref_quartier (id),
        FOREIGN KEY (avenue_id) REFERENCES ref_avenue (id)
      )
    ''');

    // Create parcelles table
    await db.execute('''
      CREATE TABLE parcelles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code_parcelle TEXT,
        reference_cadastrale TEXT,
        commune TEXT,
        quartier TEXT,
        rue_avenue TEXT,
        numero_adresse TEXT,
        commune_id INTEGER,
        quartier_id INTEGER,
        avenue_id INTEGER,
        rue TEXT,
        numero_parcelle TEXT,
        superficie_m2 REAL,
        gps_lat REAL,
        gps_lon REAL,
        statut_parcelle TEXT NOT NULL,
        date_creation TEXT,
        date_mise_a_jour TEXT,
        source_donnee TEXT,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (commune_id) REFERENCES ref_commune (id),
        FOREIGN KEY (quartier_id) REFERENCES ref_quartier (id),
        FOREIGN KEY (avenue_id) REFERENCES ref_avenue (id)
      )
    ''');

    // Create personnes table (1:1 with parcelle)
    await db.execute('''
      CREATE TABLE personnes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type_personne TEXT NOT NULL,
        nom_raison_sociale TEXT,
        nif TEXT,
        contact TEXT,
        adresse_postale TEXT,
        parcelle_id INTEGER UNIQUE,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (parcelle_id) REFERENCES parcelles (id) ON DELETE CASCADE
      )
    ''');

    // Create batiments table (1:N with parcelle)
    await db.execute('''
      CREATE TABLE batiments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        parcelle_id INTEGER,
        type_batiment TEXT NOT NULL,
        nombre_etages INTEGER,
        annee_construction INTEGER,
        surface_batie_m2 REAL,
        usage_principal TEXT NOT NULL,
        statut_batiment TEXT NOT NULL,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (parcelle_id) REFERENCES parcelles (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // All schema is now defined in _onCreate at version 1.
    // Future migrations can be added here as needed.
  }

  /// Generic insert method
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  /// Generic update method
  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  /// Generic delete method
  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  /// Generic query method
  Future<List<Map<String, dynamic>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  /// Query all rows from a table
  Future<List<Map<String, dynamic>>> queryAll(String table, {String? orderBy}) async {
    final db = await database;
    return await db.query(table, orderBy: orderBy);
  }

  /// Raw query method
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Delete all data from all tables (contribuables, ref_type_activite, ref_zone_type)
  /// Also deletes all photos associated with contribuables
  /// Note: This deletes contribuables first due to foreign key constraints
  /// Returns a map with the count of deleted rows per table
  Future<Map<String, int>> deleteAllData() async {
    final db = await database;
    
    // First, get all contribuables to delete their photos
    final contribuables = await db.query('contribuables', columns: ['piece_identite_url']);
    final cameraService = CameraService();
    
    for (final row in contribuables) {
      final photoData = row['piece_identite_url'];
      if (photoData != null && photoData is String && photoData.isNotEmpty) {
        try {
          List<String> photoUrls;
          if (photoData.startsWith('[')) {
            photoUrls = List<String>.from(jsonDecode(photoData));
          } else {
            photoUrls = [photoData];
          }
          for (final photoPath in photoUrls) {
            await cameraService.deletePhoto(photoPath);
          }
        } catch (e) {
          // Continue even if photo deletion fails
        }
      }
    }
    
    // Delete contribuables first (has foreign keys to ref tables)
    final contribuablesDeleted = await db.delete('contribuables');
    
    // Delete reference tables
    final activitesDeleted = await db.delete('ref_type_activite');
    final zonesDeleted = await db.delete('ref_zone_type');
    
    return {
      'contribuables': contribuablesDeleted,
      'ref_type_activite': activitesDeleted,
      'ref_zone_type': zonesDeleted,
    };
  }
}
