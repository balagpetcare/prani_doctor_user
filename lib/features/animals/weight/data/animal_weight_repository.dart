import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/api_result.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/network/dio_helpers.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/offline/network_errors.dart';
import '../../../offline/data/outbox_item.dart';
import '../../../offline/data/outbox_service.dart';
import '../../../offline/offline_providers.dart';
import 'animal_weight_api_paths.dart';
import 'animal_weight_capture_draft.dart';
import 'animal_weight_dto.dart';

class AnimalWeightRepository {
  AnimalWeightRepository(this._dio, this._outbox);

  final Dio _dio;
  final OutboxService _outbox;

  Future<ApiResult<double>> previewTape({
    required String animalType,
    required double heartGirthCm,
    required double bodyLengthCm,
  }) async {
    try {
      final data = await postJson(_dio, AnimalWeightApiPaths.tapePreview, {
        'animalType': animalType,
        'heartGirthCm': heartGirthCm,
        'bodyLengthCm': bodyLengthCm,
      });
      final preview = data['preview'] as Map<String, dynamic>?;
      final kg = double.tryParse(preview?['estimatedKg']?.toString() ?? '');
      if (kg == null) {
        return const ApiResult.failure(
          AppException(message: 'Invalid tape preview response'),
        );
      }
      return ApiResult.success(kg);
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<AnimalWeightHistoryResult>> listHistory(
    String animalId, {
    int page = 1,
  }) async {
    try {
      final data = await getJson(
        _dio,
        AnimalWeightApiPaths.measurements(animalId),
        queryParameters: {'page': page, 'pageSize': 50},
      );
      return ApiResult.success(AnimalWeightHistoryResult.fromJson(data));
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<AnimalWeightMeasurement>> createMeasurement(
    String animalId,
    AnimalWeightCaptureDraft draft,
  ) async {
    final capture = draft.toWeightCaptureJson();
    if (capture == null) {
      return const ApiResult.failure(
        AppException(message: 'Incomplete weight capture'),
      );
    }
    final body = {'weightCapture': capture};
    try {
      final data = await postJson(
        _dio,
        AnimalWeightApiPaths.measurements(animalId),
        body,
      );
      final raw = data['measurement'] as Map<String, dynamic>?;
      if (raw == null) {
        return const ApiResult.failure(
          AppException(message: 'Invalid measurement response'),
        );
      }
      return ApiResult.success(AnimalWeightMeasurement.fromJson(raw));
    } on AppException catch (e) {
      if (isTransientNetworkError(e)) {
        await _enqueueMeasurement(animalId, body);
        return const ApiResult.failure(
          AppException(
            message: 'Saved offline — will sync when online',
            code: offlineQueuedCode,
          ),
        );
      }
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<AnimalWeightAiJob>> pollAiJob(
    String animalId,
    String jobId,
  ) async {
    try {
      final data = await getJson(
        _dio,
        AnimalWeightApiPaths.aiJob(animalId, jobId),
      );
      return ApiResult.success(AnimalWeightAiJob.fromJson(data));
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<void> _enqueueMeasurement(
    String animalId,
    Map<String, dynamic> body,
  ) async {
    final sequence = (await _outbox.listAll()).length + 1;
    await _outbox.enqueue(
      OutboxItem(
        idempotencyKey: 'animal-weight-$animalId-$sequence',
        kind: OutboxKind.animalWeightMeasurementCreate,
        payload: {'animalId': animalId, ...body},
        clientSequence: sequence,
        attemptCount: 0,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }
}

final animalWeightRepositoryProvider = Provider<AnimalWeightRepository>((ref) {
  return AnimalWeightRepository(
    ref.watch(dioProvider),
    ref.watch(outboxServiceProvider),
  );
});
