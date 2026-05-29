import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_result.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_helpers.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/offline/local_cache_contract.dart';
import '../../offline/data/local_cache_service.dart';
import '../../offline/offline_providers.dart';
import 'recommendation_api_paths.dart';
import 'recommendation_dto.dart';

class RecommendationRepository {
  RecommendationRepository(this._dio, this._cache);

  final Dio _dio;
  final LocalCacheService _cache;

  Future<ApiResult<FeedRecommendation>> getDailyRecommendation({
    required String livestockId,
    String? planDate,
    bool forceRefresh = false,
  }) async {
    final dateKey = planDate ?? DateTime.now().toIso8601String().substring(0, 10);
    try {
      final data = await getJson(
        _dio,
        RecommendationApiPaths.daily,
        queryParameters: {
          'livestockId': livestockId,
          if (planDate != null) 'planDate': planDate,
        },
      );
      final raw = data['recommendation'] as Map<String, dynamic>? ?? data;
      final recommendation = FeedRecommendation.fromJson({
        ...raw,
        'livestockId': livestockId,
      });
      await _cache.write(
        LocalCacheContract.phase4RecommendationKey(livestockId, dateKey),
        {'recommendation': raw},
        LocalCacheContract.dataTtl,
      );
      return ApiResult.success(recommendation);
    } on AppException catch (e) {
      if (!forceRefresh) {
        final cached = await _cache.read(
          LocalCacheContract.phase4RecommendationKey(livestockId, dateKey),
        );
        final raw = cached?['recommendation'];
        if (raw is Map<String, dynamic>) {
          return ApiResult.success(
            FeedRecommendation.fromJson(
              {...raw, 'livestockId': livestockId},
              fromCache: true,
            ),
          );
        }
      }
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<void>> acceptRecommendation({
    required String livestockId,
    required String planDate,
  }) async {
    try {
      await postJson(_dio, RecommendationApiPaths.accept, {
        'livestockId': livestockId,
        'planDate': planDate,
      });
      return const ApiResult.success(null);
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }
}

final recommendationRepositoryProvider = Provider<RecommendationRepository>((
  ref,
) {
  return RecommendationRepository(
    ref.watch(dioProvider),
    ref.watch(localCacheServiceProvider),
  );
});
