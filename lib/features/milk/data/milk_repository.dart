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
import 'milk_api_paths.dart';
import 'milk_dto.dart';
import 'milk_repository_contract.dart';

class MilkRepository implements MilkRepositoryContract {
  MilkRepository(this._dio, this._cache, this._outbox);

  final Dio _dio;
  final LocalCacheService _cache;
  final OutboxService _outbox;

  Future<ApiResult<MilkPageResult>>? _listInFlight;

  String _dateParam(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Future<MilkPageResult?> readCachedList() async {
    final cached = await _cache.read(LocalCacheContract.milkListKey);
    if (cached == null) return null;
    final records = (cached['records'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((j) => MilkRecord.fromJson(j, fromCache: true))
        .toList();
    return MilkPageResult(
      records: records,
      total: cached['total'] as int? ?? records.length,
      page: cached['page'] as int? ?? 1,
      limit: cached['limit'] as int? ?? 20,
      hasMore: cached['hasMore'] as bool? ?? false,
      fromCache: true,
    );
  }

  Future<void> _writeListCache(MilkPageResult page) async {
    await _cache.write(
      LocalCacheContract.milkListKey,
      {
        'records': page.records.map((r) => r.toJson()).toList(),
        'total': page.total,
        'page': page.page,
        'limit': page.limit,
        'hasMore': page.hasMore,
      },
      LocalCacheContract.profileTtl,
    );
  }

  Future<void> _writeSummaryCache(String key, MilkSummary summary) async {
    await _cache.write(
      key,
      {
        'date': summary.date,
        'from': summary.from,
        'to': summary.to,
        'totalLiters': summary.totalLiters,
        'morningLiters': summary.morningLiters,
        'eveningLiters': summary.eveningLiters,
        'byAnimal': summary.byAnimal
            .map(
              (a) => {
                'animalId': a.animalId,
                'animalName': a.animalName,
                'totalLiters': a.totalLiters,
                'morningLiters': a.morningLiters,
                'eveningLiters': a.eveningLiters,
              },
            )
            .toList(),
        'byDay': summary.byDay
            .map(
              (d) => {
                'date': d.date,
                'totalLiters': d.totalLiters,
                'morningLiters': d.morningLiters,
                'eveningLiters': d.eveningLiters,
              },
            )
            .toList(),
      },
      LocalCacheContract.profileTtl,
    );
  }

  Future<void> _writeChartsCache(MilkChartsData charts) async {
    await _cache.write(
      LocalCacheContract.milkChartsKey,
      {
        'from': charts.from,
        'to': charts.to,
        'dailyProduction': charts.dailyProduction
            .map(
              (d) => {
                'date': d.date,
                'totalLiters': d.totalLiters,
                'morningLiters': d.morningLiters,
                'eveningLiters': d.eveningLiters,
              },
            )
            .toList(),
        'weeklyTrend': charts.weeklyTrend.map((w) => {'weekStart': w.label, 'totalLiters': w.totalLiters}).toList(),
        'monthlyTrend': charts.monthlyTrend.map((m) => {'month': m.label, 'totalLiters': m.totalLiters}).toList(),
        'sessionSplit': {'morning': charts.morningLiters, 'evening': charts.eveningLiters},
      },
      LocalCacheContract.profileTtl,
    );
  }

  MilkPageResult _parseListPage(Map<String, dynamic> data) {
    final records = (data['records'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(MilkRecord.fromJson)
        .toList();
    return MilkPageResult(
      records: records,
      total: data['total'] as int? ?? records.length,
      page: data['page'] as int? ?? 1,
      limit: data['limit'] as int? ?? 20,
      hasMore: data['hasMore'] as bool? ?? false,
    );
  }

  @override
  Future<ApiResult<MilkPageResult>> listRecords({
    DateTime? from,
    DateTime? to,
    String? animalId,
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _listInFlight != null) return _listInFlight!;
    final future = _loadList(
      from: from,
      to: to,
      animalId: animalId,
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

  Future<ApiResult<MilkPageResult>> _loadList({
    DateTime? from,
    DateTime? to,
    String? animalId,
    required int page,
    required int limit,
  }) async {
    try {
      final now = DateTime.now();
      final query = <String, dynamic>{
        'page': page,
        'limit': limit,
        'from': _dateParam(from ?? now.subtract(const Duration(days: 7))),
        'to': _dateParam(to ?? now),
        if (animalId != null && animalId.isNotEmpty) 'animalId': animalId,
      };
      final data = await getJson(_dio, MilkApiPaths.milk, queryParameters: query);
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

  @override
  Future<ApiResult<MilkRecord>> getRecord(String id) async {
    try {
      final data = await getJson(_dio, MilkApiPaths.record(id));
      final raw = data['record'];
      if (raw is! Map<String, dynamic>) {
        return ApiResult.failure(const AppException(message: 'Record not found'));
      }
      final record = MilkRecord.fromJson(raw);
      await _cache.write(
        LocalCacheContract.milkDetailKey(id),
        {'record': record.toJson()},
        LocalCacheContract.profileTtl,
      );
      return ApiResult.success(record);
    } on AppException catch (e) {
      final cached = await _cache.read(LocalCacheContract.milkDetailKey(id));
      if (cached != null) {
        return ApiResult.success(
          MilkRecord.fromJson(cached['record'] as Map<String, dynamic>, fromCache: true),
        );
      }
      return ApiResult.failure(e);
    }
  }

  Future<void> _enqueue(OutboxKind kind, Map<String, dynamic> payload, String keySuffix) async {
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

  Future<void> _optimisticUpsert(MilkRecord record) async {
    final cached = await readCachedList();
    final existing = cached?.records ?? [];
    final updated = [record, ...existing.where((r) => r.id != record.id)];
    await _writeListCache(
      MilkPageResult(
        records: updated,
        total: updated.length,
        page: 1,
        limit: 20,
        hasMore: false,
      ),
    );
    await _cache.write(
      LocalCacheContract.milkDetailKey(record.id),
      {'record': record.toJson()},
      LocalCacheContract.profileTtl,
    );
  }

  Future<void> _optimisticRemove(String id) async {
    final cached = await readCachedList();
    if (cached == null) return;
    final updated = cached.records.where((r) => r.id != id).toList();
    await _writeListCache(
      MilkPageResult(
        records: updated,
        total: updated.length,
        page: cached.page,
        limit: cached.limit,
        hasMore: cached.hasMore,
      ),
    );
  }

  @override
  Future<ApiResult<MilkRecord>> createRecord(MilkInput input) async {
    final body = input.toCreateJson();
    final tempId = 'local-milk-${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = MilkRecord(
      id: tempId,
      customerId: '',
      animalId: input.animalId,
      animalName: '',
      farmRef: input.farmRef,
      recordedDate: input.recordedDate,
      session: input.session,
      quantityLiters: input.quantityLiters,
      notes: input.notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      pendingSync: true,
      fromCache: true,
    );
    await _optimisticUpsert(optimistic);

    try {
      final data = await postJson(_dio, MilkApiPaths.milk, body);
      final raw = data['record'];
      if (raw is! Map<String, dynamic>) {
        return ApiResult.failure(const AppException(message: 'Invalid create response'));
      }
      final record = MilkRecord.fromJson(raw);
      await _optimisticUpsert(record);
      await clearDraft();
      return ApiResult.success(record);
    } on AppException catch (e) {
      if (isTransientNetworkError(e) || e.code == 'CONFLICT') {
        await _enqueue(OutboxKind.milkCreate, body, tempId);
        if (isTransientNetworkError(e)) {
          return ApiResult.failure(
            const AppException(message: 'Saved offline — will sync when online', code: offlineQueuedCode),
          );
        }
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<MilkRecord>> updateRecord(String id, MilkInput input) async {
    final body = input.toPatchJson();
    final existingResult = await getRecord(id);
    final existing = existingResult.when(success: (r) => r, failure: (_) => null);
    if (existing != null) {
      await _optimisticUpsert(
        existing.copyWith(
          animalId: input.animalId,
          farmRef: input.farmRef,
          recordedDate: input.recordedDate,
          session: input.session,
          quantityLiters: input.quantityLiters,
          notes: input.notes,
          pendingSync: true,
          updatedAt: DateTime.now(),
        ),
      );
    }

    try {
      final data = await patchJson(_dio, MilkApiPaths.record(id), body);
      final raw = data['record'];
      if (raw is! Map<String, dynamic>) {
        return ApiResult.failure(const AppException(message: 'Invalid update response'));
      }
      final record = MilkRecord.fromJson(raw);
      await _optimisticUpsert(record);
      await clearDraft(recordId: id);
      return ApiResult.success(record);
    } on AppException catch (e) {
      if (isTransientNetworkError(e)) {
        await _enqueue(OutboxKind.milkPatch, {...body, 'id': id}, id);
        return ApiResult.failure(
          const AppException(message: 'Saved offline — will sync when online', code: offlineQueuedCode),
        );
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<void>> deleteRecord(String id) async {
    await _optimisticRemove(id);
    try {
      await deleteJson(_dio, MilkApiPaths.record(id));
      return const ApiResult.success(null);
    } on AppException catch (e) {
      if (isTransientNetworkError(e)) {
        await _enqueue(OutboxKind.milkDelete, {'id': id}, id);
        return ApiResult.failure(
          const AppException(message: 'Queued delete — will sync when online', code: offlineQueuedCode),
        );
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<MilkSummary>> getSummary({DateTime? date, DateTime? from, DateTime? to}) async {
    final cacheKey = date != null
        ? LocalCacheContract.milkSummaryKey(_dateParam(date))
        : LocalCacheContract.milkSummaryKey('range');
    try {
      final query = <String, dynamic>{
        if (date != null) 'date': _dateParam(date),
        if (from != null) 'from': _dateParam(from),
        if (to != null) 'to': _dateParam(to),
      };
      final data = await getJson(_dio, MilkApiPaths.summary, queryParameters: query);
      final raw = data['summary'];
      if (raw is! Map<String, dynamic>) {
        return ApiResult.failure(const AppException(message: 'Invalid summary response'));
      }
      final summary = MilkSummary.fromJson(raw);
      await _writeSummaryCache(cacheKey, summary);
      return ApiResult.success(summary);
    } on AppException catch (e) {
      final cached = await _cache.read(cacheKey);
      if (cached != null) {
        return ApiResult.success(MilkSummary.fromJson(cached, fromCache: true));
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<MilkChartsData>> getCharts({DateTime? from, DateTime? to}) async {
    try {
      final now = DateTime.now();
      final query = <String, dynamic>{
        'from': _dateParam(from ?? now.subtract(const Duration(days: 30))),
        'to': _dateParam(to ?? now),
        'period': 'daily',
      };
      final data = await getJson(_dio, MilkApiPaths.charts, queryParameters: query);
      final raw = data['charts'];
      if (raw is! Map<String, dynamic>) {
        return ApiResult.failure(const AppException(message: 'Invalid charts response'));
      }
      final charts = MilkChartsData.fromJson(raw);
      await _writeChartsCache(charts);
      return ApiResult.success(charts);
    } on AppException catch (e) {
      final cached = await _cache.read(LocalCacheContract.milkChartsKey);
      if (cached != null) {
        return ApiResult.success(MilkChartsData.fromJson(cached, fromCache: true));
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<void> saveDraft(MilkInput input, {String? recordId}) async {
    await _cache.write(
      recordId == null ? LocalCacheContract.milkDraftKey : LocalCacheContract.milkEditDraftKey(recordId),
      input.toDraftJson(),
      LocalCacheContract.profileTtl,
    );
  }

  @override
  Future<MilkInput?> readDraft({String? recordId}) async {
    final raw = await _cache.read(
      recordId == null ? LocalCacheContract.milkDraftKey : LocalCacheContract.milkEditDraftKey(recordId),
    );
    if (raw == null || raw.isEmpty) return null;
    return MilkInput.fromDraftJson(raw);
  }

  @override
  Future<void> clearDraft({String? recordId}) async {
    await _cache.write(
      recordId == null ? LocalCacheContract.milkDraftKey : LocalCacheContract.milkEditDraftKey(recordId),
      {},
      Duration.zero,
    );
  }
}

final milkRepositoryProvider = Provider<MilkRepositoryContract>((ref) {
  return MilkRepository(
    ref.watch(dioProvider),
    ref.watch(localCacheServiceProvider),
    ref.watch(outboxServiceProvider),
  );
});
