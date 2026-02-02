import 'database_helper.dart';
import '../../models/entities/contribuable_entity.dart';
import '../../../core/utils/camera_service.dart';

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
    final maps = await _dbHelper.queryAll('contribuables');
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

  /// Get contribuable by NIF
  Future<ContribuableEntity?> getContribuableByNif(String nif) async {
    final maps = await _dbHelper.query(
      'contribuables',
      where: 'nif = ?',
      whereArgs: [nif],
    );
    if (maps.isEmpty) return null;
    return ContribuableEntity.fromMap(maps.first);
  }

  /// Search contribuables by name, NIF, or phone
  Future<List<ContribuableEntity>> searchContribuables(String query) async {
    final searchTerm = '%$query%';
    final maps = await _dbHelper.query(
      'contribuables',
      where: 'nom LIKE ? OR post_nom LIKE ? OR prenom LIKE ? OR raison_sociale LIKE ? OR nif LIKE ? OR telephone1 LIKE ?',
      whereArgs: [searchTerm, searchTerm, searchTerm, searchTerm, searchTerm, searchTerm],
    );
    return maps.map((map) => ContribuableEntity.fromMap(map)).toList();
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

  /// Delete a contribuable and its associated photos
  Future<int> deleteContribuable(int id) async {
    // First, get the contribuable to access photo paths
    final contribuable = await getContribuableById(id);
    
    // Delete associated photos from storage
    if (contribuable != null && contribuable.pieceIdentiteUrls.isNotEmpty) {
      final cameraService = CameraService();
      for (final photoPath in contribuable.pieceIdentiteUrls) {
        await cameraService.deletePhoto(photoPath);
      }
    }
    
    // Then delete the database record
    return await _dbHelper.delete(
      'contribuables',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get contribuables by type
  Future<List<ContribuableEntity>> getContribuablesByType(String type) async {
    final maps = await _dbHelper.query(
      'contribuables',
      where: 'type_contribuable = ?',
      whereArgs: [type],
    );
    return maps.map((map) => ContribuableEntity.fromMap(map)).toList();
  }

  /// Get contribuables by origine fiche
  Future<List<ContribuableEntity>> getContribuablesByOrigine(String origine) async {
    final maps = await _dbHelper.query(
      'contribuables',
      where: 'origine_fiche = ?',
      whereArgs: [origine],
    );
    return maps.map((map) => ContribuableEntity.fromMap(map)).toList();
  }

  /// Count total contribuables
  Future<int> countContribuables() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM contribuables');
    return result.first['count'] as int;
  }
}
