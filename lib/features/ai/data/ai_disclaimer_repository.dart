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
import 'ai_disclaimer_api_paths.dart';
import 'ai_disclaimer_dto.dart';

class AiDisclaimerRepository {
  AiDisclaimerRepository(this._dio, this._cache, this._settings);

  final Dio _dio;
  final LocalCacheService _cache;
  final SettingsRepository _settings;

  Future<AiDisclaimerBundle?> readCached() async {
    final cached = await _cache.read(LocalCacheContract.aiDisclaimerKey);
    if (cached == null) return null;
    return AiDisclaimerBundle.fromJson(cached, fromCache: true);
  }

  Future<void> _writeCache(AiDisclaimerBundle bundle) async {
    await _cache.write(
      LocalCacheContract.aiDisclaimerKey,
      bundle.toJson(),
      LocalCacheContract.appConfigTtl,
    );
  }

  Future<ApiResult<AiDisclaimerBundle>> loadDisclaimer({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await readCached();
      if (cached != null) return ApiResult.success(cached);
    }

    try {
      final data = await getJson(_dio, AiDisclaimerApiPaths.disclaimer);
      final bundle = AiDisclaimerBundle.fromJson(data);
      await _writeCache(bundle);
      return ApiResult.success(bundle);
    } on AppException catch (e) {
      final cached = await readCached();
      if (cached != null) return ApiResult.success(cached);
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<AiDisclaimerBundle>> accept({
    required String version,
    required AiDisclaimerAcceptSurface surface,
  }) async {
    AppException? primaryError;
    try {
      await postJson(_dio, AiDisclaimerApiPaths.accept, {
        'version': version,
        'surface': surface.apiValue,
      });
    } on AppException catch (e) {
      primaryError = e;
      final syncResult = await _settings.sync(
        SettingsSyncInput(acceptAiVersion: version),
      );
      final synced = syncResult.when(success: (_) => true, failure: (_) => false);
      if (!synced) {
        return ApiResult.failure(primaryError);
      }
    }

    return loadDisclaimer(forceRefresh: true);
  }
}

final aiDisclaimerRepositoryProvider = Provider<AiDisclaimerRepository>((ref) {
  return AiDisclaimerRepository(
    ref.watch(dioProvider),
    ref.watch(localCacheServiceProvider),
    ref.watch(settingsRepositoryProvider),
  );
});
