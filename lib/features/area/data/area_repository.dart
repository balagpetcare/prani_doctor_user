import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/area/area_cache_contract.dart';
import '../../../core/area/area_dto.dart';
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
  static const _maxPages = 5;

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
      level: 'DIVISION',
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
      path: AreaApiPaths.districts,
      cacheKey: AreaCacheContract.districtsKey(divisionId, locale),
      page: page,
      pageSize: pageSize,
      locale: locale,
      level: 'DISTRICT',
      parentId: divisionId,
      query: {'divisionId': divisionId},
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
      path: AreaApiPaths.upazilas,
      cacheKey: AreaCacheContract.upazilasKey(districtId, locale),
      page: page,
      pageSize: pageSize,
      locale: locale,
      level: 'UPAZILA',
      parentId: districtId,
      query: {'districtId': districtId},
    );
  }

  @override
  Future<AreaPage<AreaNodeDto>> getUnions({
    required String districtId,
    required String upazilaId,
    int page = 1,
    int pageSize = 20,
    String locale = 'bn',
  }) {
    return _fetchNodes(
      path: AreaApiPaths.unions,
      cacheKey: AreaCacheContract.unionsKey(upazilaId, locale),
      page: page,
      pageSize: pageSize,
      locale: locale,
      level: 'UNION',
      parentId: upazilaId,
      query: {'districtId': districtId, 'upazilaId': upazilaId},
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
      path: AreaApiPaths.villages,
      cacheKey: AreaCacheContract.villagesKey(unionId, locale),
      page: page,
      pageSize: pageSize,
      locale: locale,
      level: 'VILLAGE',
      parentId: unionId,
      query: {'unionId': unionId},
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

  @override
  Future<AreaPage<AreaSearchHitDto>> search({
    required String query,
    String level = 'ALL',
    int limit = 25,
    String locale = 'bn',
    String? divisionId,
    String? districtId,
    String? upazilaId,
    String? unionId,
  }) async {
    final data = await getJson(
      _dio,
      AreaApiPaths.search,
      queryParameters: {'q': query, 'level': level, 'limit': limit},
    );
    final items = (data['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((json) => AreaSearchHitDto.fromMobileJson(json, locale: locale))
        .toList();

    return AreaPage(
      data: items,
      meta: AreaPageMeta(
        total: items.length,
        page: 1,
        pageSize: limit,
        hasMore: false,
      ),
    );
  }

  Future<AreaPage<AreaNodeDto>> _fetchNodes({
    required String path,
    required String cacheKey,
    required int page,
    required int pageSize,
    required String locale,
    required String level,
    String? parentId,
    Map<String, dynamic>? query,
  }) async {
    final inFlight = _memory.inFlight(cacheKey);
    if (inFlight != null) return inFlight;

    final future = _fetchNodesInternal(
      path: path,
      cacheKey: cacheKey,
      page: page,
      pageSize: pageSize,
      locale: locale,
      level: level,
      parentId: parentId,
      query: query,
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
    required String level,
    String? parentId,
    Map<String, dynamic>? query,
  }) async {
    final effectivePageSize = page == 1 ? _defaultPageSize : pageSize;

    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      try {
        final first = await _fetchPage(
          path: path,
          page: page,
          pageSize: effectivePageSize,
          locale: locale,
          level: level,
          parentId: parentId,
          query: query,
        );

        final allNodes = List<AreaNodeDto>.from(first.data);
        var meta = first.meta;
        var nextPage = page + 1;

        while (page == 1 && meta.hasMore && nextPage <= _maxPages) {
          final next = await _fetchPage(
            path: path,
            page: nextPage,
            pageSize: effectivePageSize,
            locale: locale,
            level: level,
            parentId: parentId,
            query: query,
          );
          allNodes.addAll(next.data);
          meta = next.meta;
          if (next.data.isEmpty) break;
          nextPage++;
        }

        if (page == 1 && allNodes.isNotEmpty) {
          _memory.write(cacheKey, allNodes);
          await _cache.writeJson(cacheKey, {
            'cachedAt': DateTime.now().toIso8601String(),
            'items': allNodes.map(_nodeToJson).toList(),
          });
        }

        return AreaPage(
          data: allNodes,
          meta: AreaPageMeta(
            total: meta.total > 0 ? meta.total : allNodes.length,
            page: page,
            pageSize: effectivePageSize,
            hasMore: meta.hasMore && nextPage > _maxPages,
          ),
        );
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

  Future<AreaPage<AreaNodeDto>> _fetchPage({
    required String path,
    required int page,
    required int pageSize,
    required String locale,
    required String level,
    String? parentId,
    Map<String, dynamic>? query,
  }) async {
    final data = await getJson(
      _dio,
      path,
      queryParameters: {if (query != null) ...query},
    );

    final nodes = (data['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(
          (json) => AreaNodeDto.fromMobileJson(
            json,
            level: level,
            parentId: parentId,
            locale: locale,
          ),
        )
        .toList();

    return AreaPage(
      data: nodes,
      meta: AreaPageMeta(
        total: nodes.length,
        page: page,
        pageSize: pageSize,
        hasMore: false,
      ),
    );
  }

  Map<String, dynamic> _nodeToJson(AreaNodeDto node) => {
    'id': node.id,
    'slug': node.slug,
    'code': node.code,
    'nameBn': node.nameBn,
    'nameEn': node.nameEn,
    'label': node.label,
    'level': node.level,
    'parentId': node.parentId,
    'latitude': node.latitude,
    'longitude': node.longitude,
    'isVerified': node.isVerified,
  };

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

  AreaPage<AreaNodeDto> _pageFromList(
    List<AreaNodeDto> nodes, {
    bool fromCache = false,
  }) {
    return AreaPage(
      data: nodes,
      fromCache: fromCache,
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
