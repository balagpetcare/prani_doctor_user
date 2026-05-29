import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/api_result.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_helpers.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/offline/local_cache_contract.dart';
import '../../../core/offline/network_errors.dart';
import '../../offline/data/local_cache_service.dart';
import '../../offline/data/outbox_item.dart';
import '../../offline/data/outbox_service.dart';
import '../../offline/offline_providers.dart';
import 'inventory_api_paths.dart';
import 'inventory_dto.dart';
import 'inventory_repository_contract.dart';

class InventoryRepository implements InventoryRepositoryContract {
  InventoryRepository(this._dio, this._cache, this._outbox);

  final Dio _dio;
  final LocalCacheService _cache;
  final OutboxService _outbox;
  String _newIdempotencyKey() =>
      'inv-${DateTime.now().millisecondsSinceEpoch}';

  Future<void> _enqueue(
    OutboxKind kind,
    Map<String, dynamic> payload,
    String keySuffix,
  ) async {
    final sequence = (await _outbox.listAll()).length + 1;
    await _outbox.enqueue(
      OutboxItem(
        idempotencyKey: '${kind.apiValue}-$keySuffix-$sequence',
        kind: kind,
        payload: payload,
        clientSequence: sequence,
        attemptCount: 0,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  InventoryListResult _parseList(Map<String, dynamic> data, {bool fromCache = false}) {
    final items = (data['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((j) => InventoryItem.fromJson(j, fromCache: fromCache))
        .toList();
    final alerts = (data['lowStockAlerts'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(LowStockAlert.fromJson)
        .toList();
    return InventoryListResult(
      items: items,
      lowStockAlerts: alerts,
      page: data['page'] as int? ?? 1,
      limit: data['limit'] as int? ?? 20,
      total: data['total'] as int? ?? items.length,
      hasMore: data['hasMore'] as bool? ?? false,
      fromCache: fromCache,
      pendingSyncCount: items.where((i) => i.pendingSync).length,
    );
  }

  @override
  Future<InventorySummary?> readCachedSummary(String farmRef) async {
    final cached = await _cache.read(LocalCacheContract.inventorySummaryKey(farmRef));
    if (cached == null) return null;
    final summary = cached['summary'];
    if (summary is! Map<String, dynamic>) return null;
    return InventorySummary.fromJson(summary, fromCache: true);
  }

  @override
  Future<InventoryListResult?> readCachedFeedList(String farmRef) async {
    final cached = await _cache.read(LocalCacheContract.inventoryFeedListKey(farmRef));
    if (cached == null) return null;
    return _parseList(cached, fromCache: true);
  }

  @override
  Future<InventoryListResult?> readCachedMedicineList(String farmRef) async {
    final cached =
        await _cache.read(LocalCacheContract.inventoryMedicineListKey(farmRef));
    if (cached == null) return null;
    return _parseList(cached, fromCache: true);
  }

  @override
  Future<ApiResult<InventorySummary>> getSummary(
    String farmRef, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await readCachedSummary(farmRef);
      if (cached != null) {
        unawaited(_refreshSummary(farmRef));
        return ApiResult.success(cached);
      }
    }
    return _refreshSummary(farmRef);
  }

  Future<ApiResult<InventorySummary>> _refreshSummary(String farmRef) async {
    try {
      final data = await getJson(
        _dio,
        InventoryApiPaths.summary,
        queryParameters: {'farmRef': farmRef},
      );
      final raw = data['summary'];
      if (raw is! Map<String, dynamic>) {
        return const ApiResult.failure(
          AppException(message: 'Invalid inventory summary'),
        );
      }
      final summary = InventorySummary.fromJson(raw);
      await _cache.write(
        LocalCacheContract.inventorySummaryKey(farmRef),
        {'summary': raw},
        LocalCacheContract.profileTtl,
      );
      return ApiResult.success(summary);
    } on AppException catch (e) {
      final cached = await readCachedSummary(farmRef);
      if (cached != null) return ApiResult.success(cached);
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<InventoryListResult>> listFeed(
    String farmRef, {
    String search = '',
    int page = 1,
    int limit = 50,
    bool forceRefresh = false,
  }) {
    return _list(
      farmRef: farmRef,
      path: InventoryApiPaths.feed,
      cacheKey: LocalCacheContract.inventoryFeedListKey(farmRef),
      search: search,
      page: page,
      limit: limit,
      forceRefresh: forceRefresh,
    );
  }

  @override
  Future<ApiResult<InventoryListResult>> listMedicine(
    String farmRef, {
    String search = '',
    int page = 1,
    int limit = 50,
    bool forceRefresh = false,
  }) {
    return _list(
      farmRef: farmRef,
      path: InventoryApiPaths.medicine,
      cacheKey: LocalCacheContract.inventoryMedicineListKey(farmRef),
      search: search,
      page: page,
      limit: limit,
      forceRefresh: forceRefresh,
    );
  }

  Future<ApiResult<InventoryListResult>> _list({
    required String farmRef,
    required String path,
    required String cacheKey,
    String search = '',
    int page = 1,
    int limit = 50,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _cache.read(cacheKey);
      if (cached != null) {
        unawaited(_fetchList(path, farmRef, cacheKey, search, page, limit));
        return ApiResult.success(_parseList(cached, fromCache: true));
      }
    }
    return _fetchList(path, farmRef, cacheKey, search, page, limit);
  }

  Future<ApiResult<InventoryListResult>> _fetchList(
    String path,
    String farmRef,
    String cacheKey,
    String search,
    int page,
    int limit,
  ) async {
    try {
      final data = await getJson(
        _dio,
        path,
        queryParameters: {
          'farmRef': farmRef,
          if (search.isNotEmpty) 'search': search,
          'page': page,
          'limit': limit,
        },
      );
      final pageResult = _parseList(data);
      await _cache.write(cacheKey, data, LocalCacheContract.profileTtl);
      await _cache.delete(LocalCacheContract.inventorySummaryKey(farmRef));
      return ApiResult.success(pageResult);
    } on AppException catch (e) {
      final cached = await _cache.read(cacheKey);
      if (cached != null) {
        return ApiResult.success(_parseList(cached, fromCache: true));
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<List<InventoryItem>>> addFeedCatalogBatch(
    InventoryAddBatchInput input,
  ) async {
    final idempotencyKey = input.idempotencyKey ?? _newIdempotencyKey();
    final body = {...input.toJson(), 'idempotencyKey': idempotencyKey};

    try {
      final data = await postJson(_dio, InventoryApiPaths.add, body);
      final itemsRaw = data['items'];
      if (itemsRaw is List) {
        final items = itemsRaw
            .whereType<Map<String, dynamic>>()
            .map(InventoryItem.fromJson)
            .toList();
        await _invalidateFarmCaches(input.farmRef);
        return ApiResult.success(items);
      }
      final itemRaw = data['item'];
      if (itemRaw is Map<String, dynamic>) {
        final item = InventoryItem.fromJson(itemRaw);
        await _invalidateFarmCaches(input.farmRef);
        return ApiResult.success([item]);
      }
      return const ApiResult.failure(
        AppException(message: 'Invalid inventory batch response'),
      );
    } on AppException catch (e) {
      if (!isTransientNetworkError(e)) return ApiResult.failure(e);
      await _enqueue(OutboxKind.inventoryAdd, body, idempotencyKey);
      final optimistic = input.items
          .map(
            (row) => InventoryItem(
              id: 'local-inv-${row.feedId}-${DateTime.now().millisecondsSinceEpoch}',
              customerId: '',
              farmRef: input.farmRef,
              inventoryType: InventoryType.feed,
              displayName: '',
              feedType: null,
              feedUnit: null,
              medicineUnit: null,
              lowStockThreshold: row.lowStockLevel,
              allowNegativeStock: false,
              isActive: true,
              notes: input.notes,
              quantityOnHand: row.openingQuantity ?? 0,
              quantityReserved: 0,
              quantityAvailable: row.openingQuantity ?? 0,
              isLowStock: false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              pendingSync: true,
              fromCache: true,
            ),
          )
          .toList();
      for (final item in optimistic) {
        await _mergeIntoListCache(input.farmRef, InventoryType.feed, item);
      }
      return ApiResult.success(optimistic);
    }
  }

  @override
  Future<ApiResult<InventoryItem>> addStock(InventoryAddInput input) async {
    final idempotencyKey = input.idempotencyKey ?? _newIdempotencyKey();
    final body = {...input.toJson(), 'idempotencyKey': idempotencyKey};

    try {
      final data = await postJson(_dio, InventoryApiPaths.add, body);
      final itemRaw = data['item'];
      if (itemRaw is! Map<String, dynamic>) {
        return const ApiResult.failure(
          AppException(message: 'Invalid inventory response'),
        );
      }
      final item = InventoryItem.fromJson(itemRaw);
      await _invalidateFarmCaches(input.farmRef);
      return ApiResult.success(item);
    } on AppException catch (e) {
      if (!isTransientNetworkError(e)) return ApiResult.failure(e);
      if (input.operation == 'CREATE_ITEM') {
        await _enqueue(OutboxKind.inventoryAdd, body, idempotencyKey);
        final optimistic = InventoryItem(
          id: 'local-inv-${DateTime.now().millisecondsSinceEpoch}',
          customerId: '',
          farmRef: input.farmRef,
          inventoryType: input.inventoryType,
          displayName: input.displayName ?? '',
          feedType: input.feedType,
          feedUnit: input.feedUnit,
          medicineUnit: input.medicineUnit,
          lowStockThreshold: input.lowStockThreshold,
          allowNegativeStock: false,
          isActive: true,
          notes: input.notes,
          quantityOnHand: input.quantity ?? 0,
          quantityReserved: 0,
          quantityAvailable: input.quantity ?? 0,
          isLowStock: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          pendingSync: true,
          fromCache: true,
        );
        await _mergeIntoListCache(input.farmRef, input.inventoryType, optimistic);
        return ApiResult.success(optimistic);
      }
      return ApiResult.failure(
        AppException(code: offlineQueuedCode, message: e.message),
      );
    }
  }

  @override
  Future<ApiResult<InventoryItem>> consumeStock(InventoryConsumeInput input) async {
    final idempotencyKey = input.idempotencyKey ?? _newIdempotencyKey();
    final body = {...input.toJson(), 'idempotencyKey': idempotencyKey};

    try {
      final data = await postJson(_dio, InventoryApiPaths.consume, body);
      final itemRaw = data['item'];
      if (itemRaw is! Map<String, dynamic>) {
        return const ApiResult.failure(
          AppException(message: 'Invalid consume response'),
        );
      }
      final item = InventoryItem.fromJson(itemRaw);
      await _invalidateFarmCaches(input.farmRef);
      return ApiResult.success(item);
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<void> _invalidateFarmCaches(String farmRef) async {
    await _cache.delete(LocalCacheContract.inventorySummaryKey(farmRef));
    await _cache.delete(LocalCacheContract.inventoryFeedListKey(farmRef));
    await _cache.delete(LocalCacheContract.inventoryMedicineListKey(farmRef));
  }

  Future<void> _mergeIntoListCache(
    String farmRef,
    InventoryType type,
    InventoryItem item,
  ) async {
    final key = type == InventoryType.feed
        ? LocalCacheContract.inventoryFeedListKey(farmRef)
        : LocalCacheContract.inventoryMedicineListKey(farmRef);
    final cached = await _cache.read(key);
    final items = <Map<String, dynamic>>[
      item.toJson(),
      ...((cached?['items'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()),
    ];
    await _cache.write(key, {
      'items': items,
      'lowStockAlerts': cached?['lowStockAlerts'] ?? [],
      'page': 1,
      'limit': 50,
      'total': items.length,
      'hasMore': false,
    }, LocalCacheContract.profileTtl);
  }
}

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(
    ref.watch(dioProvider),
    ref.watch(localCacheServiceProvider),
    ref.watch(outboxServiceProvider),
  );
});
