import 'database_helper.dart';
import '../../models/entities/ref_type_activite_entity.dart';

/// Local datasource for RefTypeActivite (reference table)
/// This is a read-only datasource - data is populated via SQL
class RefTypeActiviteLocalDatasource {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Get all activity types
  Future<List<RefTypeActiviteEntity>> getAllTypeActivites() async {
    final maps = await _dbHelper.query(
      'ref_type_activite',
      orderBy: 'libelle ASC',
    );
    return maps.map((map) => RefTypeActiviteEntity.fromMap(map)).toList();
  }

  /// Get activity type by ID
  Future<RefTypeActiviteEntity?> getTypeActiviteById(int id) async {
    final maps = await _dbHelper.query(
      'ref_type_activite',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return RefTypeActiviteEntity.fromMap(maps.first);
  }

  /// Search activity types by libelle
  Future<List<RefTypeActiviteEntity>> searchTypeActivites(String query) async {
    final searchTerm = '%$query%';
    final maps = await _dbHelper.query(
      'ref_type_activite',
      where: 'libelle LIKE ?',
      whereArgs: [searchTerm],
      orderBy: 'libelle ASC',
    );
    return maps.map((map) => RefTypeActiviteEntity.fromMap(map)).toList();
  }

  /// Insert a list of RefTypeActiviteEntity with their exact id and libelle
  /// This uses INSERT OR REPLACE to handle existing records
  /// Useful for seeding reference data or syncing from external source
  Future<void> insertAll(List<RefTypeActiviteEntity> typeActivites) async {
    final db = await _dbHelper.database;
    
    // Use a batch for better performance with multiple inserts
    final batch = db.batch();
    
    for (final typeActivite in typeActivites) {
      batch.rawInsert(
        'INSERT OR REPLACE INTO ref_type_activite (id, libelle) VALUES (?, ?)',
        [typeActivite.id, typeActivite.libelle],
      );
    }
    
    await batch.commit(noResult: true);
  }
}
