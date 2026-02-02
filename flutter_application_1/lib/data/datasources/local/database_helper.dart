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
        adresse TEXT NOT NULL,
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
        updated_at TEXT,
        FOREIGN KEY (activite_id) REFERENCES ref_type_activite (id),
        FOREIGN KEY (zone_id) REFERENCES ref_zone_type (id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    if (oldVersion < 4) {
      // Create contribuables table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS contribuables (
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
          adresse TEXT NOT NULL,
          origine_fiche TEXT NOT NULL,
          statut INTEGER,
          gps_latitude REAL,
          gps_longitude REAL,
          piece_identite_url TEXT,
          date_inscription TEXT,
          created_at TEXT,
          cree_par TEXT NOT NULL,
          date_maj TEXT,
          maj_par TEXT,
          updated_at TEXT
        )
      ''');
    }
    if (oldVersion < 5) {
      // Create ref_type_activite reference table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ref_type_activite (
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

      // Add activite_id column to contribuables
      await db.execute('ALTER TABLE contribuables ADD COLUMN activite_id INTEGER');
    }
    if (oldVersion < 6) {
      // Create ref_zone_type reference table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ref_zone_type (
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

      // Add zone_id column to contribuables
      await db.execute('ALTER TABLE contribuables ADD COLUMN zone_id INTEGER');
    }
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
