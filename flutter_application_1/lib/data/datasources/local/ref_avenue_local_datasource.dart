import 'database_helper.dart';
import '../../models/entities/ref_avenue_entity.dart';

/// Local datasource for RefAvenue (reference table)
/// This is a read-only datasource - data is populated via SQL
class RefAvenueLocalDatasource {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Get all avenues
  Future<List<RefAvenueEntity>> getAllAvenues() async {
    final maps = await _dbHelper.query(
      'ref_avenue',
      orderBy: 'libelle ASC',
    );
    return maps.map((map) => RefAvenueEntity.fromMap(map)).toList();
  }

  /// Get avenue by ID
  Future<RefAvenueEntity?> getAvenueById(int id) async {
    final maps = await _dbHelper.query(
      'ref_avenue',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return RefAvenueEntity.fromMap(maps.first);
  }

  /// Search avenues by libelle
  Future<List<RefAvenueEntity>> searchAvenues(String query) async {
    final searchTerm = '%$query%';
    final maps = await _dbHelper.query(
      'ref_avenue',
      where: 'libelle LIKE ?',
      whereArgs: [searchTerm],
      orderBy: 'libelle ASC',
    );
    return maps.map((map) => RefAvenueEntity.fromMap(map)).toList();
  }

  /// Insert a list of RefAvenueEntity with their exact id and libelle
  Future<void> insertAll(List<RefAvenueEntity> avenues) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (final avenue in avenues) {
      batch.rawInsert(
        'INSERT OR REPLACE INTO ref_avenue (id, libelle) VALUES (?, ?)',
        [avenue.id, avenue.libelle],
      );
    }
    await batch.commit(noResult: true);
  }
}
