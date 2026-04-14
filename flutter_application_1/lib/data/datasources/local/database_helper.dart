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
    // Create ref_commune reference table
    await db.execute('''
      CREATE TABLE ref_commune (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        libelle TEXT NOT NULL
      )
    ''');

    // Create ref_quartier reference table
    await db.execute('''
      CREATE TABLE ref_quartier (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        libelle TEXT NOT NULL
      )
    ''');

    // Create ref_avenue reference table
    await db.execute('''
      CREATE TABLE ref_avenue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        libelle TEXT NOT NULL
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
        rang_parcelle TEXT,
        societe_immobiliere INTEGER,
        date_creation TEXT,
        date_mise_a_jour TEXT,
        source_donnee TEXT,
        created_at TEXT,
        updated_at TEXT,
        sync_status INTEGER NOT NULL DEFAULT 0,
        sync_error TEXT,
        sync_attempts INTEGER NOT NULL DEFAULT 0,
        last_sync_at TEXT,
        photo_urls TEXT,
        FOREIGN KEY (commune_id) REFERENCES ref_commune (id),
        FOREIGN KEY (quartier_id) REFERENCES ref_quartier (id),
        FOREIGN KEY (avenue_id) REFERENCES ref_avenue (id)
      )
    ''');

    // Create contribuables table (proprietaire or locataire)
    await db.execute('''
      CREATE TABLE contribuables (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type_contribuable TEXT NOT NULL,
        nom TEXT,
        prenom TEXT,
        piece_identite TEXT,
        nom_raison_sociale TEXT,
        nif TEXT,
        contact TEXT,
        email TEXT,
        adresse_postale TEXT,
        parcelle_id INTEGER,
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

    // Create unites table (N:1 with batiment, FK to contribuable for locataire)
    await db.execute('''
      CREATE TABLE unites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        batiment_id INTEGER,
        type_unite TEXT,
        superficie REAL,
        contribuable_id INTEGER,
        montant_loyer REAL,
        date_debut_loyer TEXT,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (batiment_id) REFERENCES batiments (id) ON DELETE CASCADE,
        FOREIGN KEY (contribuable_id) REFERENCES contribuables (id) ON DELETE SET NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Database reset to v1 with contribuables table - no migrations needed
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

  /// Replace all reference tables with fresh data from backend.
  /// This force-deletes old references and inserts new rows with exact IDs.
  Future<Map<String, int>> replaceReferenceData({
    required List<Map<String, dynamic>> avenues,
    required List<Map<String, dynamic>> quartiers,
    required List<Map<String, dynamic>> communes,
  }) async {
    final db = await database;
    await db.execute('PRAGMA foreign_keys = OFF');

    try {
      return await db.transaction((txn) async {
        await txn.delete('ref_avenue');
        await txn.delete('ref_quartier');
        await txn.delete('ref_commune');

        final batch = txn.batch();

        for (final row in avenues) {
          batch.rawInsert(
            'INSERT INTO ref_avenue (id, libelle) VALUES (?, ?)',
            [row['id'], row['libelle']],
          );
        }

        for (final row in quartiers) {
          batch.rawInsert(
            'INSERT INTO ref_quartier (id, libelle) VALUES (?, ?)',
            [row['id'], row['libelle']],
          );
        }

        for (final row in communes) {
          batch.rawInsert(
            'INSERT INTO ref_commune (id, libelle) VALUES (?, ?)',
            [row['id'], row['libelle']],
          );
        }

        await batch.commit(noResult: true);

        return {
          'avenues': avenues.length,
          'quartiers': quartiers.length,
          'communes': communes.length,
        };
      });
    } finally {
      await db.execute('PRAGMA foreign_keys = ON');
    }
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Delete all data from all tables
  /// Also deletes all photos associated with parcelles
  /// Returns a map with the count of deleted rows per table
  Future<Map<String, int>> deleteAllData() async {
    final db = await database;
    final cameraService = CameraService();
    
    // Delete parcelle photos from device storage
    final parcelles = await db.query('parcelles', columns: ['photo_urls']);
    for (final row in parcelles) {
      final photoData = row['photo_urls'];
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

    // Delete parcelle-related tables (order matters for FK constraints)
    final unitesDeleted = await db.delete('unites');
    final batimentsDeleted = await db.delete('batiments');
    final contribuablesDeleted = await db.delete('contribuables');
    final parcellesDeleted = await db.delete('parcelles');

    // Delete reference tables
    final communesDeleted = await db.delete('ref_commune');
    final quartiersDeleted = await db.delete('ref_quartier');
    final avenuesDeleted = await db.delete('ref_avenue');
    
    return {
      'parcelles': parcellesDeleted,
      'batiments': batimentsDeleted,
      'contribuables': contribuablesDeleted,
      'unites': unitesDeleted,
      'ref_commune': communesDeleted,
      'ref_quartier': quartiersDeleted,
      'ref_avenue': avenuesDeleted,
    };
  }
}
