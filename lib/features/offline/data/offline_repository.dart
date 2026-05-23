import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_result.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_helpers.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/offline/offline_dto.dart';
import '../../../core/offline/offline_repository_contract.dart';

class OfflineRepository {
  OfflineRepository(this._dio);

  final Dio _dio;

  Future<ApiResult<SyncStatusDto>> getSyncStatus({String? deviceId}) async {
    try {
      final data = await getJson(
        _dio,
        OfflineRepositoryContract.syncStatusPath,
        queryParameters: {'deviceId': ?deviceId},
      );
      return ApiResult.success(SyncStatusDto.fromJson(data));
    } on AppException catch (e) {
      return ApiResult.failure(e);
    } catch (e) {
      return ApiResult.failure(
        AppException(message: 'Could not load sync status', cause: e),
      );
    }
  }

  Future<ApiResult<SyncResponseDto>> sync({
    String? deviceId,
    OfflineConnectivityMode? connectivityMode,
    bool? manualOverride,
    String mode = 'foreground',
    List<SyncItemInput>? items,
  }) async {
    try {
      final data = await postJson(_dio, OfflineRepositoryContract.syncPath, {
        'deviceId': ?deviceId,
        if (connectivityMode != null)
          'connectivityMode': connectivityToApi(connectivityMode),
        'manualOverride': ?manualOverride,
        'mode': mode,
        if (items != null) 'items': items.map((e) => e.toJson()).toList(),
      });
      return ApiResult.success(SyncResponseDto.fromJson(data));
    } on AppException catch (e) {
      return ApiResult.failure(e);
    } catch (e) {
      return ApiResult.failure(AppException(message: 'Sync failed', cause: e));
    }
  }

  Future<ApiResult<SyncRetryResponseDto>> retrySync({
    List<String>? idempotencyKeys,
    bool includeDead = false,
    bool pause = false,
    bool resume = false,
  }) async {
    try {
      final data =
          await postJson(_dio, OfflineRepositoryContract.syncRetryPath, {
            'idempotencyKeys': ?idempotencyKeys,
            'includeDead': includeDead,
            'pause': pause,
            'resume': resume,
          });
      return ApiResult.success(SyncRetryResponseDto.fromJson(data));
    } on AppException catch (e) {
      return ApiResult.failure(e);
    } catch (e) {
      return ApiResult.failure(AppException(message: 'Retry failed', cause: e));
    }
  }

  Future<ApiResult<OfflineQueueDto>> getOfflineQueue() async {
    try {
      final data = await getJson(
        _dio,
        OfflineRepositoryContract.offlineQueuePath,
      );
      return ApiResult.success(OfflineQueueDto.fromJson(data));
    } on AppException catch (e) {
      return ApiResult.failure(e);
    } catch (e) {
      return ApiResult.failure(
        AppException(message: 'Could not load offline queue', cause: e),
      );
    }
  }
}

final offlineRepositoryProvider = Provider<OfflineRepository>((ref) {
  return OfflineRepository(ref.watch(dioProvider));
});
