import 'database_helper.dart';
import '../../models/entities/ref_zone_type_entity.dart';

/// Local datasource for RefZoneType (reference table)
/// This is a read-only datasource - data is populated via SQL
class RefZoneTypeLocalDatasource {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Get all zone types
  Future<List<RefZoneTypeEntity>> getAllZoneTypes() async {
    final maps = await _dbHelper.query(
      'ref_zone_type',
      orderBy: 'libelle ASC',
    );
    return maps.map((map) => RefZoneTypeEntity.fromMap(map)).toList();
  }

  /// Get zone type by ID
  Future<RefZoneTypeEntity?> getZoneTypeById(int id) async {
    final maps = await _dbHelper.query(
      'ref_zone_type',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return RefZoneTypeEntity.fromMap(maps.first);
  }

  /// Search zone types by libelle
  Future<List<RefZoneTypeEntity>> searchZoneTypes(String query) async {
    final searchTerm = '%$query%';
    final maps = await _dbHelper.query(
      'ref_zone_type',
      where: 'libelle LIKE ?',
      whereArgs: [searchTerm],
      orderBy: 'libelle ASC',
    );
    return maps.map((map) => RefZoneTypeEntity.fromMap(map)).toList();
  }

  /// Insert a list of RefZoneTypeEntity with their exact id and libelle
  /// This uses INSERT OR REPLACE to handle existing records
  /// Useful for seeding reference data or syncing from external source
  Future<void> insertAll(List<RefZoneTypeEntity> zoneTypes) async {
    final db = await _dbHelper.database;
    
    // Use a batch for better performance with multiple inserts
    final batch = db.batch();
    
    for (final zoneType in zoneTypes) {
      batch.rawInsert(
        'INSERT OR REPLACE INTO ref_zone_type (id, libelle) VALUES (?, ?)',
        [zoneType.id, zoneType.libelle],
      );
    }
    
    await batch.commit(noResult: true);
  }
}
