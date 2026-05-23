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
import 'feed_api_paths.dart';
import 'feed_dto.dart';
import 'feed_repository_contract.dart';

class FeedRepository implements FeedRepositoryContract {
  FeedRepository(this._dio, this._cache, this._outbox);

  final Dio _dio;
  final LocalCacheService _cache;
  final OutboxService _outbox;

  Future<ApiResult<FeedPageResult>>? _listInFlight;

  String _dateParam(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Future<FeedPageResult?> readCachedList() async {
    final cached = await _cache.read(LocalCacheContract.feedsListKey);
    if (cached == null) return null;
    final records = (cached['records'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((j) => FeedRecord.fromJson(j, fromCache: true))
        .toList();
    return FeedPageResult(
      records: records,
      total: cached['total'] as int? ?? records.length,
      page: cached['page'] as int? ?? 1,
      limit: cached['limit'] as int? ?? 20,
      hasMore: cached['hasMore'] as bool? ?? false,
      fromCache: true,
      pendingSyncCount:
          cached['pendingSyncCount'] as int? ?? _pendingSyncCount(records),
    );
  }

  int _pendingSyncCount(List<FeedRecord> records) =>
      records.where((r) => r.pendingSync).length;

  @override
  Future<FeedCostData?> readCachedCost() async {
    final cached = await _cache.read(LocalCacheContract.feedCostKey);
    if (cached == null) return null;
    return FeedCostData.fromJson(cached, fromCache: true);
  }

  @override
  Future<FeedAnalyticsData?> readCachedAnalytics() async {
    final cached = await _cache.read(LocalCacheContract.feedAnalyticsKey);
    if (cached == null) return null;
    return FeedAnalyticsData.fromJson(cached, fromCache: true);
  }

  Future<void> _writeListCache(FeedPageResult page) async {
    await _cache.write(LocalCacheContract.feedsListKey, {
      'records': page.records.map((r) => r.toJson()).toList(),
      'total': page.total,
      'page': page.page,
      'limit': page.limit,
      'hasMore': page.hasMore,
      'pendingSyncCount': page.pendingSyncCount,
    }, LocalCacheContract.profileTtl);
  }

  FeedPageResult _parseListPage(Map<String, dynamic> data) {
    final records = (data['records'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(FeedRecord.fromJson)
        .toList();
    return FeedPageResult(
      records: records,
      total: data['total'] as int? ?? records.length,
      page: data['page'] as int? ?? 1,
      limit: data['limit'] as int? ?? 20,
      hasMore: data['hasMore'] as bool? ?? false,
      pendingSyncCount: _pendingSyncCount(records),
    );
  }

  @override
  Future<ApiResult<FeedPageResult>> listRecords({
    DateTime? from,
    DateTime? to,
    String? animalId,
    String? batchId,
    FeedType? feedType,
    String search = '',
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _listInFlight != null) return _listInFlight!;
    final future = _loadList(
      from: from,
      to: to,
      animalId: animalId,
      batchId: batchId,
      feedType: feedType,
      search: search,
      page: page,
      limit: limit,
    );
    _listInFlight = future;
    try {
      return await future;
    } finally {
      _listInFlight = null;
    }
  }

  Future<ApiResult<FeedPageResult>> _loadList({
    DateTime? from,
    DateTime? to,
    String? animalId,
    String? batchId,
    FeedType? feedType,
    required String search,
    required int page,
    required int limit,
  }) async {
    try {
      final now = DateTime.now();
      final query = <String, dynamic>{
        'page': page,
        'limit': limit,
        'from': _dateParam(from ?? now.subtract(const Duration(days: 30))),
        'to': _dateParam(to ?? now),
        if (animalId != null && animalId.isNotEmpty) 'animalId': animalId,
        if (batchId != null && batchId.isNotEmpty) 'batchId': batchId,
        if (feedType != null) 'feedType': feedType.apiValue,
        if (search.trim().isNotEmpty) 'search': search.trim(),
      };
      final data = await getJson(
        _dio,
        FeedApiPaths.feeds,
        queryParameters: query,
      );
      final pageResult = _parseListPage(data);
      if (page == 1) await _writeListCache(pageResult);
      return ApiResult.success(pageResult);
    } on AppException catch (e) {
      if (page == 1) {
        final cached = await readCachedList();
        if (cached != null) return ApiResult.success(cached);
      }
      return ApiResult.failure(e);
    }
  }

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

  Future<void> _optimisticUpsert(FeedRecord record) async {
    final cached = await readCachedList();
    final existing = cached?.records ?? [];
    final updated = [record, ...existing.where((r) => r.id != record.id)];
    await _writeListCache(
      FeedPageResult(
        records: updated,
        total: updated.length,
        page: 1,
        limit: 20,
        hasMore: false,
      ),
    );
    await _cache.write(LocalCacheContract.feedDetailKey(record.id), {
      'record': record.toJson(),
    }, LocalCacheContract.profileTtl);
  }

  Future<void> _optimisticRemove(String id) async {
    final cached = await readCachedList();
    if (cached == null) return;
    final updated = cached.records.where((r) => r.id != id).toList();
    await _writeListCache(
      FeedPageResult(
        records: updated,
        total: updated.length,
        page: cached.page,
        limit: cached.limit,
        hasMore: cached.hasMore,
      ),
    );
  }

  @override
  Future<ApiResult<FeedRecord>> getRecord(String id) async {
    try {
      final data = await getJson(_dio, FeedApiPaths.record(id));
      final raw = data['record'];
      if (raw is! Map<String, dynamic>) {
        return const ApiResult.failure(
          AppException(message: 'Record not found'),
        );
      }
      final record = FeedRecord.fromJson(raw);
      await _cache.write(LocalCacheContract.feedDetailKey(id), {
        'record': record.toJson(),
      }, LocalCacheContract.profileTtl);
      return ApiResult.success(record);
    } on AppException catch (e) {
      final cached = await _cache.read(LocalCacheContract.feedDetailKey(id));
      if (cached != null) {
        return ApiResult.success(
          FeedRecord.fromJson(
            cached['record'] as Map<String, dynamic>,
            fromCache: true,
          ),
        );
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<FeedRecord>> createRecord(FeedInput input) async {
    final body = input.toCreateJson();
    final tempId = 'local-feed-${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = FeedRecord(
      id: tempId,
      customerId: '',
      farmRef: input.farmRef,
      animalId: input.animalId,
      batchId: input.batchId,
      batchName: input.batchName,
      feedType: input.feedType,
      amount: input.amount,
      unit: input.unit,
      costBdt: input.costBdt,
      recordedDate: input.recordedDate,
      notes: input.notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      pendingSync: true,
      fromCache: true,
    );
    await _optimisticUpsert(optimistic);

    try {
      final data = await postJson(_dio, FeedApiPaths.feeds, body);
      final raw = data['record'];
      if (raw is! Map<String, dynamic>) {
        return const ApiResult.failure(
          AppException(message: 'Invalid create response'),
        );
      }
      final record = FeedRecord.fromJson(raw);
      await _optimisticUpsert(record);
      await clearDraft();
      return ApiResult.success(record);
    } on AppException catch (e) {
      if (isTransientNetworkError(e)) {
        await _enqueue(OutboxKind.feedCreate, body, tempId);
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
  Future<ApiResult<FeedRecord>> updateRecord(String id, FeedInput input) async {
    final body = input.toPatchJson();
    final existingResult = await getRecord(id);
    if (existingResult case ApiSuccess(data: final existing)) {
      await _optimisticUpsert(
        existing.copyWith(
          farmRef: input.farmRef,
          animalId: input.animalId,
          batchId: input.batchId,
          batchName: input.batchName,
          feedType: input.feedType,
          amount: input.amount,
          unit: input.unit,
          costBdt: input.costBdt,
          recordedDate: input.recordedDate,
          notes: input.notes,
          pendingSync: true,
          updatedAt: DateTime.now(),
        ),
      );
    }

    try {
      final data = await patchJson(_dio, FeedApiPaths.record(id), body);
      final raw = data['record'];
      if (raw is! Map<String, dynamic>) {
        return const ApiResult.failure(
          AppException(message: 'Invalid update response'),
        );
      }
      final record = FeedRecord.fromJson(raw);
      await _optimisticUpsert(record);
      await clearDraft(recordId: id);
      return ApiResult.success(record);
    } on AppException catch (e) {
      if (isTransientNetworkError(e)) {
        await _enqueue(OutboxKind.feedPatch, {...body, 'id': id}, id);
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
  Future<ApiResult<void>> deleteRecord(String id) async {
    await _optimisticRemove(id);
    try {
      await deleteJson(_dio, FeedApiPaths.record(id));
      return const ApiResult.success(null);
    } on AppException catch (e) {
      if (isTransientNetworkError(e)) {
        await _enqueue(OutboxKind.feedDelete, {'id': id}, id);
        return const ApiResult.failure(
          AppException(
            message: 'Queued delete — will sync when online',
            code: offlineQueuedCode,
          ),
        );
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<FeedCostData>> getCost({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final now = DateTime.now();
      final query = <String, dynamic>{
        'from': _dateParam(from ?? now.subtract(const Duration(days: 30))),
        'to': _dateParam(to ?? now),
      };
      final data = await getJson(
        _dio,
        FeedApiPaths.cost,
        queryParameters: query,
      );
      final raw = data['cost'];
      if (raw is! Map<String, dynamic>) {
        return const ApiResult.failure(
          AppException(message: 'Invalid cost response'),
        );
      }
      final cost = FeedCostData.fromJson(raw);
      await _cache.write(
        LocalCacheContract.feedCostKey,
        raw,
        LocalCacheContract.profileTtl,
      );
      return ApiResult.success(cost);
    } on AppException catch (e) {
      final cached = await _cache.read(LocalCacheContract.feedCostKey);
      if (cached != null) {
        return ApiResult.success(
          FeedCostData.fromJson(cached, fromCache: true),
        );
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<FeedAnalyticsData>> getAnalytics({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final now = DateTime.now();
      final query = <String, dynamic>{
        'from': _dateParam(from ?? now.subtract(const Duration(days: 30))),
        'to': _dateParam(to ?? now),
      };
      final data = await getJson(
        _dio,
        FeedApiPaths.analytics,
        queryParameters: query,
      );
      final raw = data['analytics'];
      if (raw is! Map<String, dynamic>) {
        return const ApiResult.failure(
          AppException(message: 'Invalid analytics response'),
        );
      }
      final analytics = FeedAnalyticsData.fromJson(raw);
      await _cache.write(
        LocalCacheContract.feedAnalyticsKey,
        raw,
        LocalCacheContract.profileTtl,
      );
      return ApiResult.success(analytics);
    } on AppException catch (e) {
      final cached = await _cache.read(LocalCacheContract.feedAnalyticsKey);
      if (cached != null) {
        return ApiResult.success(
          FeedAnalyticsData.fromJson(cached, fromCache: true),
        );
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<void> saveDraft(FeedInput input, {String? recordId}) async {
    await _cache.write(
      recordId == null
          ? LocalCacheContract.feedDraftKey
          : LocalCacheContract.feedEditDraftKey(recordId),
      input.toDraftJson(),
      LocalCacheContract.profileTtl,
    );
  }

  @override
  Future<FeedInput?> readDraft({String? recordId}) async {
    final raw = await _cache.read(
      recordId == null
          ? LocalCacheContract.feedDraftKey
          : LocalCacheContract.feedEditDraftKey(recordId),
    );
    if (raw == null || raw.isEmpty) return null;
    return FeedInput.fromDraftJson(raw);
  }

  @override
  Future<void> clearDraft({String? recordId}) async {
    await _cache.write(
      recordId == null
          ? LocalCacheContract.feedDraftKey
          : LocalCacheContract.feedEditDraftKey(recordId),
      {},
      Duration.zero,
    );
  }
}

final feedRepositoryProvider = Provider<FeedRepositoryContract>((ref) {
  return FeedRepository(
    ref.watch(dioProvider),
    ref.watch(localCacheServiceProvider),
    ref.watch(outboxServiceProvider),
  );
});
