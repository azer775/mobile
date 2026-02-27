import '../../data/datasources/local/database_helper.dart';
import '../../data/datasources/remote/api_client.dart';

class RefsSyncResult {
  final bool success;
  final String message;
  final Map<String, int>? counts;

  const RefsSyncResult({
    required this.success,
    required this.message,
    this.counts,
  });
}

class RefsSyncService {
  static RefsSyncService? _instance;
  static RefsSyncService get instance {
    _instance ??= RefsSyncService._();
    return _instance!;
  }

  RefsSyncService._()
      : _apiClient = ApiClient(),
        _dbHelper = DatabaseHelper.instance;

  final ApiClient _apiClient;
  final DatabaseHelper _dbHelper;

  Future<RefsSyncResult> synchronize() async {
    try {
      final response = await _apiClient.get('/reftypes/all');

      if (response is! Map<String, dynamic>) {
        return const RefsSyncResult(
          success: false,
          message: 'Format de réponse invalide pour les références.',
        );
      }

      final zoneTypes = _parseRefList(response['zoneTypes']);
      final avenues = _parseRefList(response['avenues']);
      final quartiers = _parseRefList(response['quartiers']);
      final communes = _parseRefList(response['communes']);
      final typeActivites = _parseRefList(response['typeActivites']);

      final counts = await _dbHelper.replaceReferenceData(
        zoneTypes: zoneTypes,
        avenues: avenues,
        quartiers: quartiers,
        communes: communes,
        typeActivites: typeActivites,
      );

      return RefsSyncResult(
        success: true,
        message: 'Références synchronisées avec succès.',
        counts: counts,
      );
    } catch (error) {
      return RefsSyncResult(
        success: false,
        message: 'Synchronisation échouée: $error',
      );
    }
  }

  List<Map<String, dynamic>> _parseRefList(dynamic value) {
    if (value is! List) {
      return [];
    }

    final rows = <Map<String, dynamic>>[];

    for (final item in value) {
      if (item is! Map) {
        continue;
      }

      final dynamic idRaw = item['id'];
      final dynamic libelleRaw = item['libelle'];

      if (idRaw == null || libelleRaw == null) {
        continue;
      }

      final int? id = idRaw is int ? idRaw : int.tryParse(idRaw.toString());
      final String libelle = libelleRaw.toString().trim();

      if (id == null || libelle.isEmpty) {
        continue;
      }

      rows.add({
        'id': id,
        'libelle': libelle,
      });
    }

    return rows;
  }
}
