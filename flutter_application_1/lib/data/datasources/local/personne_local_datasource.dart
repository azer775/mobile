import 'database_helper.dart';
import '../../models/entities/personne_entity.dart';

/// Local datasource for Personne operations
class PersonneLocalDatasource {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Insert a new personne
  Future<int> insertPersonne(PersonneEntity personne) async {
    final map = personne.toMap();
    map.remove('id'); // Remove id for auto-increment
    return await _dbHelper.insert('personnes', map);
  }

  /// Get all personnes
  Future<List<PersonneEntity>> getAllPersonnes() async {
    final maps = await _dbHelper.queryAll('personnes', orderBy: 'created_at DESC');
    return maps.map((map) => PersonneEntity.fromMap(map)).toList();
  }

  /// Get personne by ID
  Future<PersonneEntity?> getPersonneById(int id) async {
    final maps = await _dbHelper.query(
      'personnes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return PersonneEntity.fromMap(maps.first);
  }

  /// Get personne by parcelle ID (1:1 relationship)
  Future<PersonneEntity?> getPersonneByParcelleId(int parcelleId) async {
    final maps = await _dbHelper.query(
      'personnes',
      where: 'parcelle_id = ?',
      whereArgs: [parcelleId],
    );
    if (maps.isEmpty) return null;
    return PersonneEntity.fromMap(maps.first);
  }

  /// Update a personne
  Future<int> updatePersonne(PersonneEntity personne) async {
    return await _dbHelper.update(
      'personnes',
      personne.toMap(),
      where: 'id = ?',
      whereArgs: [personne.id],
    );
  }

  /// Delete a personne by ID
  Future<int> deletePersonne(int id) async {
    return await _dbHelper.delete(
      'personnes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete personne by parcelle ID
  Future<int> deletePersonneByParcelleId(int parcelleId) async {
    return await _dbHelper.delete(
      'personnes',
      where: 'parcelle_id = ?',
      whereArgs: [parcelleId],
    );
  }

  /// Search personnes by name, NIF, or contact
  Future<List<PersonneEntity>> searchPersonnes(String query) async {
    final searchTerm = '%$query%';
    final maps = await _dbHelper.query(
      'personnes',
      where: 'nom_raison_sociale LIKE ? OR nif LIKE ? OR contact LIKE ?',
      whereArgs: [searchTerm, searchTerm, searchTerm],
    );
    return maps.map((map) => PersonneEntity.fromMap(map)).toList();
  }
}
