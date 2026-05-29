import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_result.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_helpers.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/offline/local_cache_contract.dart';
import '../../offline/data/local_cache_service.dart';
import '../../offline/offline_providers.dart';
import 'ai_escalation_disclosure_api_paths.dart';
import 'ai_escalation_disclosure_dto.dart';

class AiEscalationDisclosureRepository {
  AiEscalationDisclosureRepository(this._dio, this._cache);

  final Dio _dio;
  final LocalCacheService _cache;

  Future<AiEscalationDisclosureBundle?> readCached() async {
    final cached = await _cache.read(LocalCacheContract.aiEscalationDisclosureKey);
    if (cached == null) return null;
    return AiEscalationDisclosureBundle.fromJson(cached, fromCache: true);
  }

  Future<void> _writeCache(AiEscalationDisclosureBundle bundle) async {
    await _cache.write(
      LocalCacheContract.aiEscalationDisclosureKey,
      bundle.toJson(),
      LocalCacheContract.appConfigTtl,
    );
  }

  Future<ApiResult<AiEscalationDisclosureBundle>> load({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await readCached();
      if (cached != null) return ApiResult.success(cached);
    }

    try {
      final data = await getJson(_dio, AiEscalationDisclosureApiPaths.disclosure);
      final bundle = AiEscalationDisclosureBundle.fromJson(data);
      await _writeCache(bundle);
      return ApiResult.success(bundle);
    } on AppException catch (e) {
      final cached = await readCached();
      if (cached != null) return ApiResult.success(cached);
      return ApiResult.failure(e);
    }
  }
}

final aiEscalationDisclosureRepositoryProvider =
    Provider<AiEscalationDisclosureRepository>((ref) {
  return AiEscalationDisclosureRepository(
    ref.watch(dioProvider),
    ref.watch(localCacheServiceProvider),
  );
});
