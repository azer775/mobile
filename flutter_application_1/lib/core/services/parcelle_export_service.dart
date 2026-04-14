import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../data/datasources/local/batiment_local_datasource.dart';
import '../../data/datasources/local/parcelle_local_datasource.dart';
import '../../data/datasources/local/contribuable_local_datasource.dart';
import '../../data/datasources/local/unite_local_datasource.dart';
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
        _contribuableDatasource = ContribuableLocalDatasource(),
        _uniteDatasource = UniteLocalDatasource(),
        _dio = Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: Duration(milliseconds: ApiConstants.connectTimeout),
            receiveTimeout: Duration(milliseconds: ApiConstants.receiveTimeout),
          ),
        );

  final ParcelleLocalDatasource _parcelleDatasource;
  final BatimentLocalDatasource _batimentDatasource;
  final ContribuableLocalDatasource _contribuableDatasource;
  final UniteLocalDatasource _uniteDatasource;
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
    final formData = FormData();
    final dtoList = <Map<String, dynamic>>[];

    for (final parcelle in batch) {
      final dto = parcelle.toDto();

      if (parcelle.id != null) {
        final batiments = await _batimentDatasource.getBatimentsByParcelleId(
          parcelle.id!,
        );
        final batimentDtos = <Map<String, dynamic>>[];
        for (final bat in batiments) {
          final batDto = bat.toDto();
          if (bat.id != null) {
            final unites = await _uniteDatasource.getUnitesByBatimentId(bat.id!);
            batDto['unites'] = unites.map((u) => u.toDto()).toList();
          } else {
            batDto['unites'] = [];
          }
          batimentDtos.add(batDto);
        }
        dto['batiments'] = batimentDtos;

        final contribuable = await _contribuableDatasource.getContribuableByParcelleId(
          parcelle.id!,
        );
        dto['contribuable'] = contribuable?.toDto();
      } else {
        dto['batiments'] = [];
        dto['contribuable'] = null;
      }

      // Add photo files and track count
      int photoCount = 0;
      for (final photoPath in parcelle.photoUrls) {
        final file = File(photoPath);
        if (await file.exists()) {
          formData.files.add(MapEntry(
            'photos',
            await MultipartFile.fromFile(photoPath),
          ));
          photoCount++;
        }
      }
      dto['photoCount'] = photoCount;

      dtoList.add(dto);
    }

    formData.fields.add(MapEntry('data', jsonEncode(dtoList)));

    try {
      final response = await _dio.post(
        '/parcelles/batch',
        data: formData,
        options: Options(
          sendTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 120),
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
