import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_result.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_helpers.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/offline/local_cache_contract.dart';
import '../../../core/offline/network_errors.dart';
import '../../../core/util/api_timeout.dart';
import '../../../core/util/json_isolate.dart';
import 'home_api_guard.dart';
import '../../offline/data/local_cache_service.dart';
import '../../offline/offline_providers.dart';
import 'dashboard_api_paths.dart';
import 'dashboard_context_dto.dart';
import 'dashboard_repository_contract.dart';

/// Dashboard context — API-first with disk cache fallback.
class DashboardRepository implements DashboardRepositoryContract {
  DashboardRepository(this._dio, this._cache);

  final Dio _dio;
  final LocalCacheService _cache;

  Future<ApiResult<DashboardContext>>? _fetchInFlight;

  static const _maxAttempts = HomeApiGuard.maxApiAttempts;

  @override
  Future<DashboardContext?> readCachedDashboard() async {
    final cached = await _cache.read(LocalCacheContract.dashboardKey);
    if (cached == null) return null;
    return parseDashboardContextOffMain(cached);
  }

  Future<void> _writeCache(Map<String, dynamic> data) async {
    await _cache.write(
      LocalCacheContract.dashboardKey,
      data,
      LocalCacheContract.dashboardTtl,
    );
  }

  @override
  Future<ApiResult<DashboardContext>> getDashboardContext({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _fetchInFlight != null) {
      return _fetchInFlight!;
    }

    final future = _fetch(forceRefresh: forceRefresh);
    _fetchInFlight = future;
    try {
      return await future;
    } finally {
      _fetchInFlight = null;
    }
  }

  Future<ApiResult<DashboardContext>> _fetch({
    required bool forceRefresh,
  }) async {
    AppException? lastError;

    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        final data = await runWithTimeout(
          label: 'dashboard-context',
          timeout: HomeApiGuard.dashboardLoadTimeout,
          action: () => getJson(_dio, DashboardApiPaths.dashboardContext),
        );
        await _writeCache(data);
        return ApiResult.success(DashboardContext.fromJson(data));
      } on AppException catch (e) {
        lastError = e;
        if (e.code == '401' || e.code == '403') {
          return ApiResult.failure(e);
        }
        if (!isTransientNetworkError(e) || attempt >= _maxAttempts) break;
        await Future<void>.delayed(HomeApiGuard.retryDelay);
      } catch (e) {
        lastError = AppException(message: 'Could not load dashboard', cause: e);
        if (attempt < _maxAttempts) {
          await Future<void>.delayed(HomeApiGuard.retryDelay);
          continue;
        }
        break;
      }
    }

    final cached = await readCachedDashboard();
    if (cached != null) {
      return ApiResult.success(cached);
    }

    return ApiResult.failure(
      lastError ?? const AppException(message: 'Could not load dashboard'),
    );
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(
    ref.watch(dioProvider),
    ref.watch(localCacheServiceProvider),
  );
});
