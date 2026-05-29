import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_result.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_helpers.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/offline/local_cache_contract.dart';
import '../../offline/data/local_cache_service.dart';
import '../../offline/offline_providers.dart';
import 'analytics_api_paths.dart';
import 'analytics_dto.dart';

class LivestockAnalyticsRepository {
  LivestockAnalyticsRepository(this._dio, this._cache);

  final Dio _dio;
  final LocalCacheService _cache;

  String _rangeKey(String? from, String? to) => '${from ?? 'auto'}:${to ?? 'auto'}';

  Future<ApiResult<LivestockDashboardMetrics>> getDashboard({
    required String farmRef,
    String? from,
    String? to,
    bool forceRefresh = false,
  }) async {
    final cacheKey = LocalCacheContract.phase4AnalyticsDashboardKey(
      farmRef,
      _rangeKey(from, to),
    );
    try {
      final data = await getJson(
        _dio,
        LivestockAnalyticsApiPaths.dashboard,
        queryParameters: {
          'farmRef': farmRef,
          if (from != null) 'from': from,
          if (to != null) 'to': to,
        },
      );
      final raw = data['dashboard'] as Map<String, dynamic>? ?? data;
      final metrics = LivestockDashboardMetrics.fromJson(raw);
      await _cache.write(
        cacheKey,
        {'dashboard': raw},
        LocalCacheContract.dataTtl,
      );
      return ApiResult.success(metrics);
    } on AppException catch (e) {
      if (!forceRefresh) {
        final cached = await _cache.read(cacheKey);
        final raw = cached?['dashboard'];
        if (raw is Map<String, dynamic>) {
          return ApiResult.success(
            LivestockDashboardMetrics.fromJson(raw, fromCache: true),
          );
        }
      }
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<FeedEfficiencyMetrics>> getFeedEfficiency({
    required String farmRef,
    String? from,
    String? to,
    bool forceRefresh = false,
  }) async {
    try {
      final data = await getJson(
        _dio,
        LivestockAnalyticsApiPaths.feedEfficiency,
        queryParameters: {
          'farmRef': farmRef,
          if (from != null) 'from': from,
          if (to != null) 'to': to,
        },
      );
      final raw = data['efficiency'] as Map<String, dynamic>? ?? data;
      return ApiResult.success(FeedEfficiencyMetrics.fromJson(raw));
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<ProfitLossMetrics>> getProfitLoss({
    required String farmRef,
    String? from,
    String? to,
    bool forceRefresh = false,
  }) async {
    try {
      final data = await getJson(
        _dio,
        LivestockAnalyticsApiPaths.profitLoss,
        queryParameters: {
          'farmRef': farmRef,
          if (from != null) 'from': from,
          if (to != null) 'to': to,
        },
      );
      final raw = data['profitLoss'] as Map<String, dynamic>? ?? data;
      return ApiResult.success(ProfitLossMetrics.fromJson(raw));
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }
}

final livestockAnalyticsRepositoryProvider =
    Provider<LivestockAnalyticsRepository>((ref) {
      return LivestockAnalyticsRepository(
        ref.watch(dioProvider),
        ref.watch(localCacheServiceProvider),
      );
    });
