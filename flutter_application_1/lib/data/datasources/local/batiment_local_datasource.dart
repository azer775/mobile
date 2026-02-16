import 'database_helper.dart';
import '../../models/entities/batiment_entity.dart';

/// Local datasource for Batiment operations
class BatimentLocalDatasource {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Insert a new batiment
  Future<int> insertBatiment(BatimentEntity batiment) async {
    final map = batiment.toMap();
    map.remove('id'); // Remove id for auto-increment
    return await _dbHelper.insert('batiments', map);
  }

  /// Insert multiple batiments at once
  Future<void> insertBatiments(List<BatimentEntity> batiments) async {
    for (final batiment in batiments) {
      await insertBatiment(batiment);
    }
  }

  /// Get all batiments
  Future<List<BatimentEntity>> getAllBatiments() async {
    final maps = await _dbHelper.queryAll('batiments', orderBy: 'created_at DESC');
    return maps.map((map) => BatimentEntity.fromMap(map)).toList();
  }

  /// Get batiment by ID
  Future<BatimentEntity?> getBatimentById(int id) async {
    final maps = await _dbHelper.query(
      'batiments',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return BatimentEntity.fromMap(maps.first);
  }

  /// Get all batiments for a parcelle (1:N relationship)
  Future<List<BatimentEntity>> getBatimentsByParcelleId(int parcelleId) async {
    final maps = await _dbHelper.query(
      'batiments',
      where: 'parcelle_id = ?',
      whereArgs: [parcelleId],
      orderBy: 'created_at ASC',
    );
    return maps.map((map) => BatimentEntity.fromMap(map)).toList();
  }

  /// Update a batiment
  Future<int> updateBatiment(BatimentEntity batiment) async {
    return await _dbHelper.update(
      'batiments',
      batiment.toMap(),
      where: 'id = ?',
      whereArgs: [batiment.id],
    );
  }

  /// Delete a batiment by ID
  Future<int> deleteBatiment(int id) async {
    return await _dbHelper.delete(
      'batiments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all batiments for a parcelle
  Future<int> deleteBatimentsByParcelleId(int parcelleId) async {
    return await _dbHelper.delete(
      'batiments',
      where: 'parcelle_id = ?',
      whereArgs: [parcelleId],
    );
  }

  /// Count batiments for a parcelle
  Future<int> countBatimentsByParcelleId(int parcelleId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM batiments WHERE parcelle_id = ?',
      [parcelleId],
    );
    return result.first['count'] as int;
  }
}
