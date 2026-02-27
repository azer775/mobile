import 'dart:convert';
import 'package:dio/dio.dart';
import '../../data/datasources/local/batiment_local_datasource.dart';
import '../../data/datasources/local/parcelle_local_datasource.dart';
import '../../data/datasources/local/personne_local_datasource.dart';
import '../../data/models/entities/parcelle_entity.dart';
import '../constants/api_constants.dart';

class ExportParcelleBatchResult {
  final bool success;
  final int syncedCount;
  final int failedCount;
  final String? error;

  const ExportParcelleBatchResult({
    required this.success,
    required this.syncedCount,
    required this.failedCount,
    this.error,
  });
}

class ParcelleExportService {
  static ParcelleExportService? _instance;

  static ParcelleExportService get instance {
    _instance ??= ParcelleExportService._();
    return _instance!;
  }

  ParcelleExportService._()
      : _parcelleDatasource = ParcelleLocalDatasource(),
        _batimentDatasource = BatimentLocalDatasource(),
        _personneDatasource = PersonneLocalDatasource(),
        _dio = Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: Duration(milliseconds: ApiConstants.connectTimeout),
            receiveTimeout: Duration(milliseconds: ApiConstants.receiveTimeout),
          ),
        );

  final ParcelleLocalDatasource _parcelleDatasource;
  final BatimentLocalDatasource _batimentDatasource;
  final PersonneLocalDatasource _personneDatasource;
  final Dio _dio;

  Future<ExportParcelleBatchResult> exportAll({int chunkSize = 20}) async {
    int totalSynced = 0;
    int totalFailed = 0;
    String? lastError;

    while (true) {
      final batch = await _parcelleDatasource.getUnsyncedParcelles(
        limit: chunkSize,
      );
      if (batch.isEmpty) {
        break;
      }

      final result = await _exportBatch(batch);
      totalSynced += result.syncedCount;
      totalFailed += result.failedCount;

      if (!result.success) {
        lastError = result.error;
        break;
      }
    }

    return ExportParcelleBatchResult(
      success: totalFailed == 0,
      syncedCount: totalSynced,
      failedCount: totalFailed,
      error: lastError,
    );
  }

  Future<ExportParcelleBatchResult> _exportBatch(List<ParcelleEntity> batch) async {
    if (batch.isEmpty) {
      return const ExportParcelleBatchResult(
        success: true,
        syncedCount: 0,
        failedCount: 0,
      );
    }

    final ids = batch.map((item) => item.id).whereType<int>().toList();
    final dtoList = <Map<String, dynamic>>[];

    for (final parcelle in batch) {
      final dto = parcelle.toDto();

      if (parcelle.id != null) {
        final batiments = await _batimentDatasource.getBatimentsByParcelleId(
          parcelle.id!,
        );
        dto['batiments'] = batiments.map((item) => item.toDto()).toList();

        final personne = await _personneDatasource.getPersonneByParcelleId(
          parcelle.id!,
        );
        dto['personnes'] = personne != null ? [personne.toDto()] : [];
      } else {
        dto['batiments'] = [];
        dto['personnes'] = [];
      }

      dtoList.add(dto);
    }

    try {
      final response = await _dio.post(
        '/parcelles/batch',
        data: jsonEncode(dtoList),
        options: Options(
          contentType: 'application/json',
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
          validateStatus: (status) => status != null && status >= 200 && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        await _parcelleDatasource.deleteExportedParcelles(batch);
        return ExportParcelleBatchResult(
          success: true,
          syncedCount: ids.length,
          failedCount: 0,
        );
      }

      final error =
          response.data?.toString() ?? 'Export failed with HTTP ${response.statusCode}';
      await _parcelleDatasource.markAsFailed(ids, error);
      return ExportParcelleBatchResult(
        success: false,
        syncedCount: 0,
        failedCount: ids.length,
        error: error,
      );
    } on DioException catch (error) {
      final message = error.message ?? 'Network error during export';
      await _parcelleDatasource.markAsFailed(ids, message);
      return ExportParcelleBatchResult(
        success: false,
        syncedCount: 0,
        failedCount: ids.length,
        error: message,
      );
    }
  }
}
