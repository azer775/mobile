import 'database_helper.dart';
import '../../models/entities/ref_quartier_entity.dart';

/// Local datasource for RefQuartier (reference table)
/// This is a read-only datasource - data is populated via SQL
class RefQuartierLocalDatasource {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Get all quartiers
  Future<List<RefQuartierEntity>> getAllQuartiers() async {
    final maps = await _dbHelper.query(
      'ref_quartier',
      orderBy: 'libelle ASC',
    );
    return maps.map((map) => RefQuartierEntity.fromMap(map)).toList();
  }

  /// Get quartier by ID
  Future<RefQuartierEntity?> getQuartierById(int id) async {
    final maps = await _dbHelper.query(
      'ref_quartier',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return RefQuartierEntity.fromMap(maps.first);
  }

  /// Search quartiers by libelle
  Future<List<RefQuartierEntity>> searchQuartiers(String query) async {
    final searchTerm = '%$query%';
    final maps = await _dbHelper.query(
      'ref_quartier',
      where: 'libelle LIKE ?',
      whereArgs: [searchTerm],
      orderBy: 'libelle ASC',
    );
    return maps.map((map) => RefQuartierEntity.fromMap(map)).toList();
  }

  /// Insert a list of RefQuartierEntity with their exact id and libelle
  Future<void> insertAll(List<RefQuartierEntity> quartiers) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (final quartier in quartiers) {
      batch.rawInsert(
        'INSERT OR REPLACE INTO ref_quartier (id, libelle) VALUES (?, ?)',
        [quartier.id, quartier.libelle],
      );
    }
    await batch.commit(noResult: true);
  }
}
