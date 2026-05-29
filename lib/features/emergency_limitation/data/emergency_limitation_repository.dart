import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_result.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_helpers.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/offline/local_cache_contract.dart';
import '../../offline/data/local_cache_service.dart';
import '../../offline/offline_providers.dart';
import '../../settings/data/settings_dto.dart';
import '../../settings/data/settings_repository.dart';
import 'emergency_limitation_api_paths.dart';
import 'emergency_limitation_dto.dart';

class EmergencyLimitationRepository {
  EmergencyLimitationRepository(this._dio, this._cache, this._settings);

  final Dio _dio;
  final LocalCacheService _cache;
  final SettingsRepository _settings;

  Future<EmergencyLimitationBundle?> readCached() async {
    final cached = await _cache.read(LocalCacheContract.emergencyLimitationKey);
    if (cached == null) return null;
    return EmergencyLimitationBundle.fromJson(cached, fromCache: true);
  }

  Future<void> _writeCache(EmergencyLimitationBundle bundle) async {
    await _cache.write(
      LocalCacheContract.emergencyLimitationKey,
      bundle.toJson(),
      LocalCacheContract.appConfigTtl,
    );
  }

  Future<ApiResult<EmergencyLimitationBundle>> loadLimitation({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await readCached();
      if (cached != null) return ApiResult.success(cached);
    }

    try {
      final data = await getJson(_dio, EmergencyLimitationApiPaths.limitation);
      final bundle = EmergencyLimitationBundle.fromJson(data);
      await _writeCache(bundle);
      return ApiResult.success(bundle);
    } on AppException catch (e) {
      final cached = await readCached();
      if (cached != null) return ApiResult.success(cached);
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<EmergencyLimitationBundle>> accept({
    required String version,
    required EmergencyLimitationAcceptSurface surface,
    String? serviceRequestId,
  }) async {
    AppException? primaryError;
    try {
      await postJson(_dio, EmergencyLimitationApiPaths.accept, {
        'version': version,
        'surface': surface.apiValue,
        if (serviceRequestId != null) 'serviceRequestId': serviceRequestId,
      });
    } on AppException catch (e) {
      primaryError = e;
      final syncResult = await _settings.sync(
        SettingsSyncInput(acceptEmergencyVersion: version),
      );
      final synced = syncResult.when(success: (_) => true, failure: (_) => false);
      if (!synced) {
        return ApiResult.failure(primaryError);
      }
    }

    return loadLimitation(forceRefresh: true);
  }
}

final emergencyLimitationRepositoryProvider = Provider<EmergencyLimitationRepository>((ref) {
  return EmergencyLimitationRepository(
    ref.watch(dioProvider),
    ref.watch(localCacheServiceProvider),
    ref.watch(settingsRepositoryProvider),
  );
});
