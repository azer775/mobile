import 'database_helper.dart';
import '../../models/entities/unite_entity.dart';

/// Local datasource for Unite operations
class UniteLocalDatasource {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Insert a new unite
  Future<int> insertUnite(UniteEntity unite) async {
    final map = unite.toMap();
    map.remove('id'); // Remove id for auto-increment
    return await _dbHelper.insert('unites', map);
  }

  /// Insert multiple unites at once
  Future<void> insertUnites(List<UniteEntity> unites) async {
    for (final unite in unites) {
      await insertUnite(unite);
    }
  }

  /// Get all unites
  Future<List<UniteEntity>> getAllUnites() async {
    final maps = await _dbHelper.queryAll('unites', orderBy: 'created_at DESC');
    return maps.map((map) => UniteEntity.fromMap(map)).toList();
  }

  /// Get unite by ID
  Future<UniteEntity?> getUniteById(int id) async {
    final maps = await _dbHelper.query(
      'unites',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return UniteEntity.fromMap(maps.first);
  }

  /// Get all unites for a batiment (N:1 relationship)
  Future<List<UniteEntity>> getUnitesByBatimentId(int batimentId) async {
    final maps = await _dbHelper.query(
      'unites',
      where: 'batiment_id = ?',
      whereArgs: [batimentId],
      orderBy: 'created_at ASC',
    );
    return maps.map((map) => UniteEntity.fromMap(map)).toList();
  }

  /// Update a unite
  Future<int> updateUnite(UniteEntity unite) async {
    return await _dbHelper.update(
      'unites',
      unite.toMap(),
      where: 'id = ?',
      whereArgs: [unite.id],
    );
  }

  /// Delete a unite by ID
  Future<int> deleteUnite(int id) async {
    return await _dbHelper.delete(
      'unites',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all unites for a batiment
  Future<int> deleteUnitesByBatimentId(int batimentId) async {
    return await _dbHelper.delete(
      'unites',
      where: 'batiment_id = ?',
      whereArgs: [batimentId],
    );
  }

  /// Count unites for a batiment
  Future<int> countUnitesByBatimentId(int batimentId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM unites WHERE batiment_id = ?',
      [batimentId],
    );
    return result.first['count'] as int;
  }
}
