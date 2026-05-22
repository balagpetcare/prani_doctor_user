import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/area/area_cache_contract.dart';
import '../../../core/area/area_dto.dart';
import '../../../core/area/area_entities.dart';
import '../../../core/area/area_repository_contract.dart';
import '../../../core/cache/cache_providers.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/dio_helpers.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/offline/network_errors.dart';
import 'area_cache_store.dart';
import 'area_memory_cache.dart';

/// Bangladesh location hierarchy — API-first with memory + disk fallback.
class AreaRepository implements AreaRepositoryContract {
  AreaRepository(this._dio, this._cache);

  final Dio _dio;
  final AreaCacheStore _cache;
  final AreaMemoryCache _memory = AreaMemoryCache();

  static const _defaultPageSize = 100;
  static const _maxAttempts = 2;

  @override
  Future<AreaPage<AreaNodeDto>> getDivisions({
    int page = 1,
    int pageSize = 20,
    String locale = 'bn',
  }) {
    return _fetchNodes(
      path: AreaApiPaths.divisions,
      cacheKey: AreaCacheContract.divisionsKey(locale),
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
  }) {
    return _fetchNodes(
      path: AreaApiPaths.districts(divisionId),
      cacheKey: AreaCacheContract.districtsKey(divisionId, locale),
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
  }) {
    return _fetchNodes(
      path: AreaApiPaths.upazilas(districtId),
      cacheKey: AreaCacheContract.upazilasKey(districtId, locale),
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
  }) {
    return _fetchNodes(
      path: AreaApiPaths.unions(upazilaId),
      cacheKey: AreaCacheContract.unionsKey(upazilaId, locale),
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
  }) {
    return _fetchNodes(
      path: AreaApiPaths.villages(unionId),
      cacheKey: AreaCacheContract.villagesKey(unionId, locale),
      page: page,
      pageSize: pageSize,
      locale: locale,
    );
  }

  /// Loads cached division lists into memory — non-blocking cold boot helper.
  Future<void> warmFromDisk({String locale = 'bn'}) async {
    final key = AreaCacheContract.divisionsKey(locale);
    final cached = await _readCachedList(key);
    if (cached != null && cached.isNotEmpty) {
      _memory.warm(key, cached);
    }
  }

  /// Fetches with cache metadata for providers.
  Future<AreaLevelResult> fetchLevel(Future<AreaPage<AreaNodeDto>> Function() load) async {
    try {
      final page = await load();
      if (page.data.isEmpty) return AreaLevelResult.empty;
      return AreaLevelResult(nodes: page.data);
    } on AppException catch (e) {
      if (isTransientNetworkError(e)) rethrow;
      rethrow;
    }
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
    required int page,
    required int pageSize,
    required String locale,
  }) async {
    final inFlight = _memory.inFlight(cacheKey);
    if (inFlight != null) return inFlight;

    final future = _fetchNodesInternal(
      path: path,
      cacheKey: cacheKey,
      page: page,
      pageSize: pageSize,
      locale: locale,
    );
    _memory.track(cacheKey, future);
    return future;
  }

  Future<AreaPage<AreaNodeDto>> _fetchNodesInternal({
    required String path,
    required String cacheKey,
    required int page,
    required int pageSize,
    required String locale,
  }) async {
    final effectivePageSize = page == 1 ? _defaultPageSize : pageSize;

    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      try {
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
            .map(AreaNodeDto.fromJson)
            .toList();

        if (page == 1 && nodes.isNotEmpty) {
          _memory.write(cacheKey, nodes);
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
      } on AppException catch (e) {
        final cached = await _loadFallback(cacheKey);
        if (cached != null) return cached;
        if (attempt + 1 < _maxAttempts && isTransientNetworkError(e)) {
          continue;
        }
        rethrow;
      } on DioException catch (e) {
        final cached = await _loadFallback(cacheKey);
        if (cached != null) return cached;
        if (attempt + 1 < _maxAttempts) continue;
        throw ApiEnvelope.fromDioException(e);
      }
    }

    return AreaPage(
      data: const [],
      meta: AreaPageMeta(
        total: 0,
        page: page,
        pageSize: effectivePageSize,
        hasMore: false,
      ),
    );
  }

  Future<AreaPage<AreaNodeDto>?> _loadFallback(String cacheKey) async {
    final mem = _memory.read(cacheKey);
    if (mem != null && mem.isNotEmpty) {
      return _pageFromList(mem, fromCache: true);
    }
    final disk = await _readCachedList(cacheKey);
    if (disk != null && disk.isNotEmpty) {
      _memory.write(cacheKey, disk);
      return _pageFromList(disk, fromCache: true);
    }
    return null;
  }

  AreaPage<AreaNodeDto> _pageFromList(List<AreaNodeDto> nodes, {bool fromCache = false}) {
    return AreaPage(
      data: nodes,
      meta: AreaPageMeta(
        total: nodes.length,
        page: 1,
        pageSize: nodes.length,
        hasMore: false,
      ),
    );
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

typedef LocationRepository = AreaRepository;

final areaCacheStoreProvider = Provider<AreaCacheStore>((ref) {
  return AreaCacheStore(ref.watch(cacheStoreProvider));
});

final areaRepositoryProvider = Provider<AreaRepository>((ref) {
  return AreaRepository(
    ref.watch(dioProvider),
    ref.watch(areaCacheStoreProvider),
  );
});

final locationRepositoryProvider = areaRepositoryProvider;
