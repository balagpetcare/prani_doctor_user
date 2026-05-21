import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/area/area_cache_contract.dart';
import '../../../core/area/area_dto.dart';
import '../../../core/area/area_repository_contract.dart';
import '../../../core/cache/cache_providers.dart';
import '../../../core/network/dio_helpers.dart';
import '../../../core/network/dio_provider.dart';
import 'area_cache_store.dart';

class AreaRepository implements AreaRepositoryContract {
  AreaRepository(this._dio, this._cache);

  final Dio _dio;
  final AreaCacheStore _cache;

  static const _defaultPageSize = 100;

  @override
  Future<AreaPage<AreaNodeDto>> getDivisions({
    int page = 1,
    int pageSize = 20,
    String locale = 'bn',
  }) async {
    return _fetchNodes(
      path: AreaApiPaths.divisions,
      cacheKey: AreaCacheContract.divisionsKey(locale),
      levelParser: (json) => AreaNodeDto.fromJson(json),
      page: page,
      pageSize: pageSize,
      locale: locale,
    );
  }

  @override
  Future<AreaPage<AreaNodeDto>> getDistricts(
    String divisionId, {
    int page = 1,
    int pageSize = 20,
    String locale = 'bn',
  }) async {
    return _fetchNodes(
      path: AreaApiPaths.districts(divisionId),
      cacheKey: AreaCacheContract.districtsKey(divisionId, locale),
      levelParser: (json) => AreaNodeDto.fromJson(json),
      page: page,
      pageSize: pageSize,
      locale: locale,
    );
  }

  @override
  Future<AreaPage<AreaNodeDto>> getUpazilas(
    String districtId, {
    int page = 1,
    int pageSize = 20,
    String locale = 'bn',
  }) async {
    return _fetchNodes(
      path: AreaApiPaths.upazilas(districtId),
      cacheKey: AreaCacheContract.upazilasKey(districtId, locale),
      levelParser: (json) => AreaNodeDto.fromJson(json),
      page: page,
      pageSize: pageSize,
      locale: locale,
    );
  }

  @override
  Future<AreaPage<AreaNodeDto>> getUnions(
    String upazilaId, {
    int page = 1,
    int pageSize = 20,
    String locale = 'bn',
  }) async {
    return _fetchNodes(
      path: AreaApiPaths.unions(upazilaId),
      cacheKey: AreaCacheContract.unionsKey(upazilaId, locale),
      levelParser: (json) => AreaNodeDto.fromJson(json),
      page: page,
      pageSize: pageSize,
      locale: locale,
    );
  }

  @override
  Future<AreaPage<AreaNodeDto>> getVillages(
    String unionId, {
    int page = 1,
    int pageSize = 20,
    String locale = 'bn',
  }) async {
    return _fetchNodes(
      path: AreaApiPaths.villages(unionId),
      cacheKey: AreaCacheContract.villagesKey(unionId, locale),
      levelParser: (json) => AreaNodeDto.fromJson(json),
      page: page,
      pageSize: pageSize,
      locale: locale,
    );
  }

  @override
  Future<AreaPage<AreaSearchHitDto>> search({
    required String query,
    String level = 'ALL',
    int page = 1,
    int pageSize = 20,
    String locale = 'bn',
    String? divisionId,
    String? districtId,
    String? upazilaId,
    String? unionId,
  }) async {
    final result = await getJsonList(
      _dio,
      AreaApiPaths.search,
      queryParameters: {
        'q': query,
        'level': level,
        'page': page,
        'pageSize': pageSize,
        'locale': locale,
        if (divisionId != null) 'divisionId': divisionId,
        if (districtId != null) 'districtId': districtId,
        if (upazilaId != null) 'upazilaId': upazilaId,
        if (unionId != null) 'unionId': unionId,
      },
    );

    final nodes = result.data
        .whereType<Map<String, dynamic>>()
        .map(AreaSearchHitDto.fromJson)
        .toList();
    final meta = result.meta != null
        ? AreaPageMeta.fromJson(result.meta!)
        : AreaPageMeta(total: nodes.length, page: page, pageSize: pageSize, hasMore: false);

    return AreaPage(data: nodes, meta: meta);
  }

  Future<AreaPage<AreaNodeDto>> _fetchNodes({
    required String path,
    required String cacheKey,
    required AreaNodeDto Function(Map<String, dynamic> json) levelParser,
    required int page,
    required int pageSize,
    required String locale,
  }) async {
    if (page == 1) {
      final cached = await _readCachedList(cacheKey);
      if (cached != null) {
        return AreaPage(
          data: cached,
          meta: AreaPageMeta(
            total: cached.length,
            page: 1,
            pageSize: cached.length,
            hasMore: false,
          ),
        );
      }
    }

    final effectivePageSize = page == 1 ? _defaultPageSize : pageSize;
    final result = await getJsonList(
      _dio,
      path,
      queryParameters: {
        'page': page,
        'pageSize': effectivePageSize,
        'locale': locale,
      },
    );

    final nodes = result.data
        .whereType<Map<String, dynamic>>()
        .map(levelParser)
        .toList();

    if (page == 1 && nodes.isNotEmpty) {
      await _cache.writeJson(cacheKey, {
        'cachedAt': DateTime.now().toIso8601String(),
        'items': result.data,
      });
    }

    final meta = result.meta != null
        ? AreaPageMeta.fromJson(result.meta!)
        : AreaPageMeta(
            total: nodes.length,
            page: page,
            pageSize: effectivePageSize,
            hasMore: false,
          );

    return AreaPage(data: nodes, meta: meta);
  }

  Future<List<AreaNodeDto>?> _readCachedList(String cacheKey) async {
    final cached = await _cache.readJson(cacheKey);
    if (cached == null) return null;

    final cachedAtRaw = cached['cachedAt'] as String?;
    if (cachedAtRaw != null) {
      final cachedAt = DateTime.tryParse(cachedAtRaw);
      if (cachedAt != null &&
          DateTime.now().difference(cachedAt) > AreaCacheContract.offlineTtl) {
        return null;
      }
    }

    final items = cached['items'];
    if (items is! List) return null;

    return items
        .whereType<Map>()
        .map((e) => AreaNodeDto.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

final areaCacheStoreProvider = Provider<AreaCacheStore>((ref) {
  return AreaCacheStore(ref.watch(cacheStoreProvider));
});

final areaRepositoryProvider = Provider<AreaRepository>((ref) {
  return AreaRepository(
    ref.watch(dioProvider),
    ref.watch(areaCacheStoreProvider),
  );
});
