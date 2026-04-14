import 'database_helper.dart';
import '../../models/entities/contribuable_entity.dart';

/// Local datasource for Contribuable operations
class ContribuableLocalDatasource {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Insert a new contribuable
  Future<int> insertContribuable(ContribuableEntity contribuable) async {
    final map = contribuable.toMap();
    map.remove('id'); // Remove id for auto-increment
    return await _dbHelper.insert('contribuables', map);
  }

  /// Get all contribuables
  Future<List<ContribuableEntity>> getAllContribuables() async {
    final maps = await _dbHelper.queryAll('contribuables', orderBy: 'created_at DESC');
    return maps.map((map) => ContribuableEntity.fromMap(map)).toList();
  }

  /// Get contribuable by ID
  Future<ContribuableEntity?> getContribuableById(int id) async {
    final maps = await _dbHelper.query(
      'contribuables',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ContribuableEntity.fromMap(maps.first);
  }

  /// Get contribuable by parcelle ID (1:1 relationship)
  Future<ContribuableEntity?> getContribuableByParcelleId(int parcelleId) async {
    final maps = await _dbHelper.query(
      'contribuables',
      where: 'parcelle_id = ?',
      whereArgs: [parcelleId],
    );
    if (maps.isEmpty) return null;
    return ContribuableEntity.fromMap(maps.first);
  }

  /// Update a contribuable
  Future<int> updateContribuable(ContribuableEntity contribuable) async {
    return await _dbHelper.update(
      'contribuables',
      contribuable.toMap(),
      where: 'id = ?',
      whereArgs: [contribuable.id],
    );
  }

  /// Delete a contribuable by ID
  Future<int> deleteContribuable(int id) async {
    return await _dbHelper.delete(
      'contribuables',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete contribuable by parcelle ID
  Future<int> deleteContribuableByParcelleId(int parcelleId) async {
    return await _dbHelper.delete(
      'contribuables',
      where: 'parcelle_id = ?',
      whereArgs: [parcelleId],
    );
  }

  /// Search contribuables by name, NIF, contact, or email
  Future<List<ContribuableEntity>> searchContribuables(String query) async {
    final searchTerm = '%$query%';
    final maps = await _dbHelper.query(
      'contribuables',
      where: 'nom LIKE ? OR prenom LIKE ? OR nom_raison_sociale LIKE ? OR nif LIKE ? OR contact LIKE ? OR email LIKE ?',
      whereArgs: [searchTerm, searchTerm, searchTerm, searchTerm, searchTerm, searchTerm],
    );
    return maps.map((map) => ContribuableEntity.fromMap(map)).toList();
  }
}
