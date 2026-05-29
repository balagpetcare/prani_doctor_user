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
import 'phase4_feed_api_paths.dart';
import 'phase4_feed_dto.dart';
import 'phase4_feed_repository_contract.dart';

class Phase4FeedRepository implements Phase4FeedRepositoryContract {
  Phase4FeedRepository(this._dio, this._cache, this._outbox);

  final Dio _dio;
  final LocalCacheService _cache;
  final OutboxService _outbox;

  Phase4FeedPageResult<Phase4FeedItem> _parseFeedItems(
    Map<String, dynamic> data, {
    bool fromCache = false,
  }) {
    final items = (data['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((j) => Phase4FeedItem.fromJson(j, fromCache: fromCache))
        .toList();
    return Phase4FeedPageResult(
      items: items,
      page: data['page'] as int? ?? 1,
      pageSize: data['limit'] as int? ?? 20,
      total: data['total'] as int? ?? items.length,
      hasMore: data['hasMore'] as bool? ?? false,
      fromCache: fromCache,
    );
  }

  Phase4FeedPageResult<Phase4FeedInventoryItem> _parseInventory(
    Map<String, dynamic> data, {
    bool fromCache = false,
  }) {
    final items = (data['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((j) => Phase4FeedInventoryItem.fromJson(j, fromCache: fromCache))
        .toList();
    return Phase4FeedPageResult(
      items: items,
      page: data['page'] as int? ?? 1,
      pageSize: data['limit'] as int? ?? 20,
      total: data['total'] as int? ?? items.length,
      hasMore: data['hasMore'] as bool? ?? false,
      fromCache: fromCache,
    );
  }

  @override
  Future<Phase4FeedPageResult<Phase4FeedItem>?> readCachedFeedItems(
    String farmRef,
  ) async {
    final cached = await _cache.read(LocalCacheContract.phase4FeedItemsKey(farmRef));
    if (cached == null) return null;
    return _parseFeedItems(cached, fromCache: true);
  }

  @override
  Future<Phase4FeedPageResult<Phase4FeedInventoryItem>?> readCachedInventory(
    String farmRef,
  ) async {
    final cached =
        await _cache.read(LocalCacheContract.phase4FeedInventoryKey(farmRef));
    if (cached == null) return null;
    return _parseInventory(cached, fromCache: true);
  }

  @override
  Future<ApiResult<Phase4FeedPageResult<Phase4FeedItem>>> listFeedItems({
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
    bool forceRefresh = false,
  }) async {
    try {
      final data = await getJson(
        _dio,
        Phase4FeedApiPaths.feedItems,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          if (category != null && category.isNotEmpty) 'category': category,
        },
      );
      final result = _parseFeedItems(data);
      if (page == 1) {
        await _cache.write(
          LocalCacheContract.phase4FeedItemsKey('global'),
          data,
          LocalCacheContract.dataTtl,
        );
      }
      return ApiResult.success(result);
    } on AppException catch (e) {
      if (!forceRefresh) {
        final cached = await readCachedFeedItems('global');
        if (cached != null) return ApiResult.success(cached);
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<Phase4FeedItem>> getFeedItem(
    String id, {
    bool forceRefresh = false,
  }) async {
    try {
      final data = await getJson(_dio, Phase4FeedApiPaths.feedItem(id));
      final raw = data['item'] as Map<String, dynamic>? ?? data;
      final item = Phase4FeedItem.fromJson(raw);
      await _cache.write(
        LocalCacheContract.phase4FeedItemDetailKey(id),
        {'item': item.toJson()},
        LocalCacheContract.dataTtl,
      );
      return ApiResult.success(item);
    } on AppException catch (e) {
      if (!forceRefresh) {
        final cached = await _cache.read(
          LocalCacheContract.phase4FeedItemDetailKey(id),
        );
        final raw = cached?['item'];
        if (raw is Map<String, dynamic>) {
          return ApiResult.success(
            Phase4FeedItem.fromJson(raw, fromCache: true),
          );
        }
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<Phase4FeedPageResult<Phase4FeedInventoryItem>>>
  listInventory({
    required String farmRef,
    int page = 1,
    int limit = 20,
    String? search,
    bool forceRefresh = false,
  }) async {
    try {
      final data = await getJson(
        _dio,
        Phase4FeedApiPaths.feedInventory,
        queryParameters: {
          'farmRef': farmRef,
          'page': page,
          'limit': limit,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        },
      );
      final result = _parseInventory(data);
      if (page == 1) {
        await _cache.write(
          LocalCacheContract.phase4FeedInventoryKey(farmRef),
          data,
          LocalCacheContract.dataTtl,
        );
      }
      return ApiResult.success(result);
    } on AppException catch (e) {
      if (!forceRefresh) {
        final cached = await readCachedInventory(farmRef);
        if (cached != null) return ApiResult.success(cached);
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<List<Phase4LowStockAlert>>> listLowStockAlerts(
    String farmRef,
  ) async {
    try {
      final data = await getJson(
        _dio,
        Phase4FeedApiPaths.feedInventoryAlerts,
        queryParameters: {'farmRef': farmRef},
      );
      final alerts = (data['alerts'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Phase4LowStockAlert.fromJson)
          .toList();
      return ApiResult.success(alerts);
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<void> _enqueue(OutboxKind kind, Map<String, dynamic> payload) async {
    final sequence = (await _outbox.listAll()).length + 1;
    await _outbox.enqueue(
      OutboxItem(
        idempotencyKey:
            '${kind.apiValue}-$sequence-${DateTime.now().millisecondsSinceEpoch}',
        kind: kind,
        payload: payload,
        clientSequence: sequence,
        attemptCount: 0,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  @override
  Future<ApiResult<Phase4FeedInventoryItem>> recordPurchase(
    Phase4FeedPurchaseInput input,
  ) async {
    try {
      final data = await postJson(
        _dio,
        Phase4FeedApiPaths.feedInventoryPurchase,
        input.toJson(),
      );
      final inventoryRaw =
          data['inventory'] as Map<String, dynamic>? ??
          (data['item'] as Map<String, dynamic>?);
      if (inventoryRaw == null) {
        return const ApiResult.failure(
          AppException(message: 'Invalid purchase response'),
        );
      }
      await clearPurchaseDraft();
      return ApiResult.success(
        Phase4FeedInventoryItem.fromJson(inventoryRaw),
      );
    } on AppException catch (e) {
      if (isTransientNetworkError(e)) {
        await _enqueue(OutboxKind.phase4FeedPurchase, input.toJson());
        return const ApiResult.failure(
          AppException(
            message: 'Saved offline — will sync when online',
            code: offlineQueuedCode,
          ),
        );
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<Phase4FeedConsumptionRecord>> recordConsumption(
    Phase4FeedConsumptionInput input,
  ) async {
    try {
      final data = await postJson(
        _dio,
        Phase4FeedApiPaths.feedConsumption,
        input.toJson(),
      );
      final raw = data['record'] as Map<String, dynamic>?;
      if (raw == null) {
        return const ApiResult.failure(
          AppException(message: 'Invalid consumption response'),
        );
      }
      await clearConsumptionDraft();
      return ApiResult.success(Phase4FeedConsumptionRecord.fromJson(raw));
    } on AppException catch (e) {
      if (isTransientNetworkError(e)) {
        await _enqueue(OutboxKind.phase4FeedConsumption, input.toJson());
        return const ApiResult.failure(
          AppException(
            message: 'Saved offline — will sync when online',
            code: offlineQueuedCode,
          ),
        );
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<Phase4FeedPageResult<Phase4FeedConsumptionRecord>>>
  listConsumption({
    required String farmRef,
    int page = 1,
    int limit = 20,
    String? livestockId,
    bool forceRefresh = false,
  }) async {
    try {
      final data = await getJson(
        _dio,
        Phase4FeedApiPaths.feedConsumption,
        queryParameters: {
          'farmRef': farmRef,
          'page': page,
          'limit': limit,
          if (livestockId != null) 'livestockId': livestockId,
        },
      );
      final items = (data['items'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Phase4FeedConsumptionRecord.fromJson)
          .toList();
      final result = Phase4FeedPageResult(
        items: items,
        page: data['page'] as int? ?? page,
        pageSize: data['limit'] as int? ?? limit,
        total: data['total'] as int? ?? items.length,
        hasMore: data['hasMore'] as bool? ?? false,
      );
      if (page == 1) {
        await _cache.write(
          LocalCacheContract.phase4FeedConsumptionKey(farmRef),
          data,
          LocalCacheContract.dataTtl,
        );
      }
      return ApiResult.success(result);
    } on AppException catch (e) {
      if (!forceRefresh) {
        final cached = await _cache.read(
          LocalCacheContract.phase4FeedConsumptionKey(farmRef),
        );
        if (cached != null) {
          final items = (cached['items'] as List<dynamic>? ?? [])
              .whereType<Map<String, dynamic>>()
              .map(Phase4FeedConsumptionRecord.fromJson)
              .toList();
          return ApiResult.success(
            Phase4FeedPageResult(
              items: items,
              page: cached['page'] as int? ?? 1,
              pageSize: cached['limit'] as int? ?? 20,
              total: cached['total'] as int? ?? items.length,
              hasMore: cached['hasMore'] as bool? ?? false,
              fromCache: true,
            ),
          );
        }
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<Phase4FeedPurchaseInput?> readPurchaseDraft() async {
    final cached = await _cache.read(LocalCacheContract.phase4FeedPurchaseDraftKey);
    if (cached == null || cached.isEmpty) return null;
    return Phase4FeedPurchaseInput.fromJson(cached);
  }

  @override
  Future<void> savePurchaseDraft(Phase4FeedPurchaseInput input) async {
    await _cache.write(
      LocalCacheContract.phase4FeedPurchaseDraftKey,
      input.toJson(),
      LocalCacheContract.profileTtl,
    );
  }

  @override
  Future<void> clearPurchaseDraft() async {
    await _cache.write(
      LocalCacheContract.phase4FeedPurchaseDraftKey,
      {},
      Duration.zero,
    );
  }

  @override
  Future<Phase4FeedConsumptionInput?> readConsumptionDraft() async {
    final cached =
        await _cache.read(LocalCacheContract.phase4FeedConsumptionDraftKey);
    if (cached == null || cached.isEmpty) return null;
    return Phase4FeedConsumptionInput.fromJson(cached);
  }

  @override
  Future<void> saveConsumptionDraft(Phase4FeedConsumptionInput input) async {
    await _cache.write(
      LocalCacheContract.phase4FeedConsumptionDraftKey,
      input.toJson(),
      LocalCacheContract.profileTtl,
    );
  }

  @override
  Future<void> clearConsumptionDraft() async {
    await _cache.write(
      LocalCacheContract.phase4FeedConsumptionDraftKey,
      {},
      Duration.zero,
    );
  }
}

final phase4FeedRepositoryProvider = Provider<Phase4FeedRepository>((ref) {
  return Phase4FeedRepository(
    ref.watch(dioProvider),
    ref.watch(localCacheServiceProvider),
    ref.watch(outboxServiceProvider),
  );
});
