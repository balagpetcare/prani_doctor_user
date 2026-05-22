import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_result.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_helpers.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/offline/local_cache_contract.dart';
import '../../offline/data/local_cache_service.dart';
import '../../offline/offline_providers.dart';
import 'app_config_api_paths.dart';
import 'app_config_dto.dart';

/// Offline-ready app bootstrap config (`GET /api/mobile/app-config`).
class AppConfigRepository {
  AppConfigRepository(this._dio, this._cache);

  final Dio _dio;
  final LocalCacheService _cache;

  Future<AppConfigDto?> readCachedConfig() async {
    final cached = await _cache.read(LocalCacheContract.appConfigKey);
    if (cached == null) return null;
    return AppConfigDto.fromJson(cached);
  }

  Future<ApiResult<AppConfigLoadResult>> loadConfig() async {
    try {
      final data = await getJson(_dio, AppConfigApiPaths.config);
      await _cache.write(
        LocalCacheContract.appConfigKey,
        data,
        LocalCacheContract.appConfigTtl,
      );
      return ApiResult.success(
        AppConfigLoadResult(
          config: AppConfigDto.fromJson(data),
          fromCache: false,
        ),
      );
    } on AppException catch (e) {
      if (e.code == 'FORCE_UPDATE_REQUIRED') {
        return ApiResult.failure(e);
      }
      final cached = await _cache.read(LocalCacheContract.appConfigKey);
      if (cached != null) {
        return ApiResult.success(
          AppConfigLoadResult(
            config: AppConfigDto.fromJson(cached),
            fromCache: true,
          ),
        );
      }
      return ApiResult.failure(e);
    } catch (e) {
      final cached = await _cache.read(LocalCacheContract.appConfigKey);
      if (cached != null) {
        return ApiResult.success(
          AppConfigLoadResult(
            config: AppConfigDto.fromJson(cached),
            fromCache: true,
          ),
        );
      }
      return ApiResult.failure(
        AppException(message: 'Could not load app config', cause: e),
      );
    }
  }
}

final appConfigRepositoryProvider = Provider<AppConfigRepository>((ref) {
  return AppConfigRepository(
    ref.watch(dioProvider),
    ref.watch(localCacheServiceProvider),
  );
});
