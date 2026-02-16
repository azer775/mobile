import 'database_helper.dart';
import '../../models/entities/ref_commune_entity.dart';

/// Local datasource for RefCommune (reference table)
/// This is a read-only datasource - data is populated via SQL
class RefCommuneLocalDatasource {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Get all communes
  Future<List<RefCommuneEntity>> getAllCommunes() async {
    final maps = await _dbHelper.query(
      'ref_commune',
      orderBy: 'libelle ASC',
    );
    return maps.map((map) => RefCommuneEntity.fromMap(map)).toList();
  }

  /// Get commune by ID
  Future<RefCommuneEntity?> getCommuneById(int id) async {
    final maps = await _dbHelper.query(
      'ref_commune',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return RefCommuneEntity.fromMap(maps.first);
  }

  /// Search communes by libelle
  Future<List<RefCommuneEntity>> searchCommunes(String query) async {
    final searchTerm = '%$query%';
    final maps = await _dbHelper.query(
      'ref_commune',
      where: 'libelle LIKE ?',
      whereArgs: [searchTerm],
      orderBy: 'libelle ASC',
    );
    return maps.map((map) => RefCommuneEntity.fromMap(map)).toList();
  }

  /// Insert a list of RefCommuneEntity with their exact id and libelle
  Future<void> insertAll(List<RefCommuneEntity> communes) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (final commune in communes) {
      batch.rawInsert(
        'INSERT OR REPLACE INTO ref_commune (id, libelle) VALUES (?, ?)',
        [commune.id, commune.libelle],
      );
    }
    await batch.commit(noResult: true);
  }
}
