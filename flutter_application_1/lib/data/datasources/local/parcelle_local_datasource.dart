import 'database_helper.dart';
import '../../models/entities/parcelle_entity.dart';
import '../../models/entities/personne_entity.dart';
import '../../models/entities/batiment_entity.dart';

/// Local datasource for Parcelle operations
class ParcelleLocalDatasource {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Insert a new parcelle
  Future<int> insertParcelle(ParcelleEntity parcelle) async {
    final map = parcelle.toMap();
    map.remove('id'); // Remove id for auto-increment
    return await _dbHelper.insert('parcelles', map);
  }

  /// Get all parcelles
  Future<List<ParcelleEntity>> getAllParcelles() async {
    final maps = await _dbHelper.queryAll('parcelles', orderBy: 'created_at DESC');
    return maps.map((map) => ParcelleEntity.fromMap(map)).toList();
  }

  /// Get parcelle by ID
  Future<ParcelleEntity?> getParcelleById(int id) async {
    final maps = await _dbHelper.query(
      'parcelles',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ParcelleEntity.fromMap(maps.first);
  }

  /// Search parcelles by code, commune, quartier, or address
  Future<List<ParcelleEntity>> searchParcelles(String query) async {
    final searchTerm = '%$query%';
    final maps = await _dbHelper.query(
      'parcelles',
      where: 'code_parcelle LIKE ? OR commune LIKE ? OR quartier LIKE ? OR rue_avenue LIKE ? OR reference_cadastrale LIKE ?',
      whereArgs: [searchTerm, searchTerm, searchTerm, searchTerm, searchTerm],
    );
    return maps.map((map) => ParcelleEntity.fromMap(map)).toList();
  }

  /// Update a parcelle
  Future<int> updateParcelle(ParcelleEntity parcelle) async {
    return await _dbHelper.update(
      'parcelles',
      parcelle.toMap(),
      where: 'id = ?',
      whereArgs: [parcelle.id],
    );
  }

  /// Delete a parcelle (cascades to personne and batiments via FK)
  Future<int> deleteParcelle(int id) async {
    return await _dbHelper.delete(
      'parcelles',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Count total parcelles
  Future<int> countParcelles() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM parcelles');
    return result.first['count'] as int;
  }

  /// Get parcelle with its associated personne and batiments
  Future<Map<String, dynamic>?> getParcelleWithDetails(int parcelleId) async {
    final parcelle = await getParcelleById(parcelleId);
    if (parcelle == null) return null;

    final personneMaps = await _dbHelper.query(
      'personnes',
      where: 'parcelle_id = ?',
      whereArgs: [parcelleId],
    );
    final personne = personneMaps.isNotEmpty 
        ? PersonneEntity.fromMap(personneMaps.first) 
        : null;

    final batimentMaps = await _dbHelper.query(
      'batiments',
      where: 'parcelle_id = ?',
      whereArgs: [parcelleId],
    );
    final batiments = batimentMaps.map((map) => BatimentEntity.fromMap(map)).toList();

    return {
      'parcelle': parcelle,
      'personne': personne,
      'batiments': batiments,
    };
  }
}
