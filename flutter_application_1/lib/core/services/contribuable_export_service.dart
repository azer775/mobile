import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../data/datasources/local/contribuable_local_datasource.dart';
import '../../data/models/entities/contribuable_entity.dart';
import '../constants/api_constants.dart';

class ExportBatchResult {
  final bool success;
  final int syncedCount;
  final int failedCount;
  final String? error;

  const ExportBatchResult({
    required this.success,
    required this.syncedCount,
    required this.failedCount,
    this.error,
  });
}

class ContribuableExportService {
  static ContribuableExportService? _instance;
  static ContribuableExportService get instance {
    _instance ??= ContribuableExportService._();
    return _instance!;
  }

  ContribuableExportService._()
      : _datasource = ContribuableLocalDatasource(),
        _dio = Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: Duration(milliseconds: ApiConstants.connectTimeout),
            receiveTimeout: Duration(milliseconds: ApiConstants.receiveTimeout),
          ),
        );

  final ContribuableLocalDatasource _datasource;
  final Dio _dio;

  Future<ExportBatchResult> exportAll({int chunkSize = 20}) async {
    int totalSynced = 0;
    int totalFailed = 0;
    String? lastError;

    while (true) {
      final batch = await _datasource.getUnsyncedContribuables(limit: chunkSize);
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

    return ExportBatchResult(
      success: totalFailed == 0,
      syncedCount: totalSynced,
      failedCount: totalFailed,
      error: lastError,
    );
  }

  Future<ExportBatchResult> _exportBatch(List<ContribuableEntity> batch) async {
    if (batch.isEmpty) {
      return const ExportBatchResult(success: true, syncedCount: 0, failedCount: 0);
    }

    final ids = batch.map((item) => item.id).whereType<int>().toList();
    final formData = FormData();
    final dtoList = batch.map((item) => item.toDto()).toList();

    formData.fields.add(MapEntry('data', jsonEncode(dtoList)));

    for (int i = 0; i < batch.length; i++) {
      final key = 'files_$i';
      for (final filePath in batch[i].pieceIdentiteUrls) {
        final file = File(filePath);
        if (!await file.exists()) {
          continue;
        }

        formData.files.add(
          MapEntry(
            key,
            await MultipartFile.fromFile(
              filePath,
              filename: _filenameFromPath(filePath),
            ),
          ),
        );
      }
    }

    try {
      final response = await _dio.post(
        '/contribuables/batch',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
          validateStatus: (status) => status != null && status >= 200 && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        await _datasource.deleteExportedContribuables(batch);
        return ExportBatchResult(
          success: true,
          syncedCount: ids.length,
          failedCount: 0,
        );
      }

      final error = response.data?.toString() ?? 'Export failed with HTTP ${response.statusCode}';
      await _datasource.markAsFailed(ids, error);
      return ExportBatchResult(
        success: false,
        syncedCount: 0,
        failedCount: ids.length,
        error: error,
      );
    } on DioException catch (error) {
      final message = error.message ?? 'Network error during export';
      await _datasource.markAsFailed(ids, message);
      return ExportBatchResult(
        success: false,
        syncedCount: 0,
        failedCount: ids.length,
        error: message,
      );
    }
  }

  String _filenameFromPath(String path) {
    final segments = path.split(RegExp(r'[\\/]'));
    return segments.isNotEmpty ? segments.last : 'file';
  }
}
