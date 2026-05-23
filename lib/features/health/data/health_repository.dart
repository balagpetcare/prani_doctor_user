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
import 'health_api_paths.dart';
import 'health_dto.dart';
import 'health_repository_contract.dart';

class HealthRepository implements HealthRepositoryContract {
  HealthRepository(this._dio, this._cache, this._outbox);

  final Dio _dio;
  final LocalCacheService _cache;
  final OutboxService _outbox;

  Future<ApiResult<HealthPageResult>>? _listInFlight;
  Future<ApiResult<HealthTimelineResult>>? _timelineInFlight;

  String _dateParam(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Future<HealthPageResult?> readCachedList() async {
    final cached = await _cache.read(LocalCacheContract.healthHistoryListKey);
    if (cached == null) return null;
    final records = (cached['records'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((j) => HealthEvent.fromJson(j, fromCache: true))
        .toList();
    final pendingSyncCount = records.where((r) => r.pendingSync).length;
    return HealthPageResult(
      records: records,
      total: cached['total'] as int? ?? records.length,
      page: cached['page'] as int? ?? 1,
      limit: cached['limit'] as int? ?? 20,
      hasMore: cached['hasMore'] as bool? ?? false,
      pendingSyncCount: pendingSyncCount,
      fromCache: true,
    );
  }

  @override
  Future<HealthTimelineResult?> readCachedTimeline() async {
    final cached = await _cache.read(LocalCacheContract.healthTimelineKey);
    if (cached == null) return null;
    return HealthTimelineResult.fromJson(cached, fromCache: true);
  }

  Future<void> _writeListCache(HealthPageResult page) async {
    await _cache.write(LocalCacheContract.healthHistoryListKey, {
      'records': page.records.map((r) => r.toJson()).toList(),
      'total': page.total,
      'page': page.page,
      'limit': page.limit,
      'hasMore': page.hasMore,
    }, LocalCacheContract.profileTtl);
  }

  Future<void> _writeTimelineCache(HealthTimelineResult timeline) async {
    await _cache.write(LocalCacheContract.healthTimelineKey, {
      'groups': timeline.groups
          .map(
            (g) => {
              'date': g.date,
              'events': g.events.map((e) => e.toJson()).toList(),
            },
          )
          .toList(),
      'total': timeline.total,
      'page': timeline.page,
      'limit': timeline.limit,
      'hasMore': timeline.hasMore,
    }, LocalCacheContract.profileTtl);
  }

  HealthPageResult _parseListPage(Map<String, dynamic> data) {
    final records = (data['records'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(HealthEvent.fromJson)
        .toList();
    return HealthPageResult(
      records: records,
      total: data['total'] as int? ?? records.length,
      page: data['page'] as int? ?? 1,
      limit: data['limit'] as int? ?? 20,
      hasMore: data['hasMore'] as bool? ?? false,
      pendingSyncCount: records.where((r) => r.pendingSync).length,
    );
  }

  Map<String, dynamic> _listQuery({
    DateTime? from,
    DateTime? to,
    String? animalId,
    HealthEventType? eventType,
    required String search,
    required int page,
    required int limit,
  }) {
    final now = DateTime.now();
    return {
      'page': page,
      'limit': limit,
      'from': _dateParam(from ?? now.subtract(const Duration(days: 90))),
      'to': _dateParam(to ?? now),
      if (animalId != null && animalId.isNotEmpty) 'animalId': animalId,
      if (eventType != null) 'eventType': eventType.apiValue,
      if (search.trim().isNotEmpty) 'search': search.trim(),
    };
  }

  @override
  Future<ApiResult<HealthPageResult>> listRecords({
    DateTime? from,
    DateTime? to,
    String? animalId,
    HealthEventType? eventType,
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
      eventType: eventType,
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

  Future<ApiResult<HealthPageResult>> _loadList({
    DateTime? from,
    DateTime? to,
    String? animalId,
    HealthEventType? eventType,
    required String search,
    required int page,
    required int limit,
  }) async {
    try {
      final data = await getJson(
        _dio,
        HealthApiPaths.history,
        queryParameters: _listQuery(
          from: from,
          to: to,
          animalId: animalId,
          eventType: eventType,
          search: search,
          page: page,
          limit: limit,
        ),
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

  @override
  Future<ApiResult<HealthTimelineResult>> getTimeline({
    DateTime? from,
    DateTime? to,
    String? animalId,
    HealthEventType? eventType,
    String search = '',
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _timelineInFlight != null) return _timelineInFlight!;
    final future = _loadTimeline(
      from: from,
      to: to,
      animalId: animalId,
      eventType: eventType,
      search: search,
      page: page,
      limit: limit,
    );
    _timelineInFlight = future;
    try {
      return await future;
    } finally {
      _timelineInFlight = null;
    }
  }

  Future<ApiResult<HealthTimelineResult>> _loadTimeline({
    DateTime? from,
    DateTime? to,
    String? animalId,
    HealthEventType? eventType,
    required String search,
    required int page,
    required int limit,
  }) async {
    try {
      final data = await getJson(
        _dio,
        HealthApiPaths.timeline,
        queryParameters: _listQuery(
          from: from,
          to: to,
          animalId: animalId,
          eventType: eventType,
          search: search,
          page: page,
          limit: limit,
        ),
      );
      final raw = data['timeline'];
      if (raw is! Map<String, dynamic>) {
        return const ApiResult.failure(
          AppException(message: 'Invalid timeline response'),
        );
      }
      final timeline = HealthTimelineResult.fromJson(raw);
      if (page == 1) await _writeTimelineCache(timeline);
      return ApiResult.success(timeline);
    } on AppException catch (e) {
      if (page == 1) {
        final cached = await readCachedTimeline();
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

  Future<void> _optimisticUpsert(HealthEvent record) async {
    final cached = await readCachedList();
    final existing = cached?.records ?? [];
    final updated = [record, ...existing.where((r) => r.id != record.id)];
    await _writeListCache(
      HealthPageResult(
        records: updated,
        total: updated.length,
        page: 1,
        limit: 20,
        hasMore: false,
      ),
    );
    await _cache.write(
      LocalCacheContract.healthDetailKey(record.id),
      {'record': record.toJson()},
      LocalCacheContract.profileTtl,
    );
  }

  Future<void> _optimisticRemove(String id) async {
    final cached = await readCachedList();
    if (cached == null) return;
    final updated = cached.records.where((r) => r.id != id).toList();
    await _writeListCache(
      HealthPageResult(
        records: updated,
        total: updated.length,
        page: cached.page,
        limit: cached.limit,
        hasMore: cached.hasMore,
      ),
    );
  }

  @override
  Future<ApiResult<HealthEvent>> getRecord(String id) async {
    try {
      final data = await getJson(_dio, HealthApiPaths.record(id));
      final raw = data['record'];
      if (raw is! Map<String, dynamic>) {
        return const ApiResult.failure(
          AppException(message: 'Record not found'),
        );
      }
      final record = HealthEvent.fromJson(raw);
      await _cache.write(LocalCacheContract.healthDetailKey(id), {
        'record': record.toJson(),
      }, LocalCacheContract.profileTtl);
      return ApiResult.success(record);
    } on AppException catch (e) {
      final cached = await _cache.read(LocalCacheContract.healthDetailKey(id));
      if (cached != null) {
        return ApiResult.success(
          HealthEvent.fromJson(
            cached['record'] as Map<String, dynamic>,
            fromCache: true,
          ),
        );
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<HealthEvent>> createRecord(HealthInput input) async {
    final body = input.toCreateJson();
    final tempId = 'local-health-${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = HealthEvent(
      id: tempId,
      customerId: '',
      farmRef: input.farmRef,
      animalId: input.animalId,
      eventType: input.eventType,
      title: input.title,
      symptoms: input.symptoms,
      diagnosis: input.diagnosis,
      diseaseName: input.diseaseName,
      treatmentRefId: input.treatmentRefId,
      vaccineRefId: input.vaccineRefId,
      notes: input.notes,
      recordedDate: input.recordedDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      pendingSync: true,
      fromCache: true,
    );
    await _optimisticUpsert(optimistic);

    try {
      final data = await postJson(_dio, HealthApiPaths.history, body);
      final raw = data['record'];
      if (raw is! Map<String, dynamic>) {
        return const ApiResult.failure(
          AppException(message: 'Invalid create response'),
        );
      }
      final record = HealthEvent.fromJson(raw);
      await _optimisticUpsert(record);
      await clearDraft();
      return ApiResult.success(record);
    } on AppException catch (e) {
      if (isTransientNetworkError(e)) {
        await _enqueue(OutboxKind.healthCreate, body, tempId);
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
  Future<ApiResult<HealthEvent>> updateRecord(
    String id,
    HealthInput input,
  ) async {
    final body = input.toPatchJson();
    final existingResult = await getRecord(id);
    if (existingResult case ApiSuccess(data: final existing)) {
      await _optimisticUpsert(
        existing.copyWith(
          farmRef: input.farmRef,
          animalId: input.animalId,
          eventType: input.eventType,
          title: input.title,
          symptoms: input.symptoms,
          diagnosis: input.diagnosis,
          diseaseName: input.diseaseName,
          treatmentRefId: input.treatmentRefId,
          vaccineRefId: input.vaccineRefId,
          notes: input.notes,
          recordedDate: input.recordedDate,
          pendingSync: true,
          updatedAt: DateTime.now(),
        ),
      );
    }

    try {
      final data = await patchJson(_dio, HealthApiPaths.record(id), body);
      final raw = data['record'];
      if (raw is! Map<String, dynamic>) {
        return const ApiResult.failure(
          AppException(message: 'Invalid update response'),
        );
      }
      final record = HealthEvent.fromJson(raw);
      await _optimisticUpsert(record);
      await clearDraft(recordId: id);
      return ApiResult.success(record);
    } on AppException catch (e) {
      if (isTransientNetworkError(e)) {
        await _enqueue(OutboxKind.healthPatch, {...body, 'id': id}, id);
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
      await deleteJson(_dio, HealthApiPaths.record(id));
      return const ApiResult.success(null);
    } on AppException catch (e) {
      if (isTransientNetworkError(e)) {
        await _enqueue(OutboxKind.healthDelete, {'id': id}, id);
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
  Future<void> saveDraft(HealthInput input, {String? recordId}) async {
    await _cache.write(
      recordId == null
          ? LocalCacheContract.healthDraftKey
          : LocalCacheContract.healthEditDraftKey(recordId),
      input.toDraftJson(),
      LocalCacheContract.profileTtl,
    );
  }

  @override
  Future<HealthInput?> readDraft({String? recordId}) async {
    final raw = await _cache.read(
      recordId == null
          ? LocalCacheContract.healthDraftKey
          : LocalCacheContract.healthEditDraftKey(recordId),
    );
    if (raw == null || raw.isEmpty) return null;
    return HealthInput.fromDraftJson(raw);
  }

  @override
  Future<void> clearDraft({String? recordId}) async {
    await _cache.write(
      recordId == null
          ? LocalCacheContract.healthDraftKey
          : LocalCacheContract.healthEditDraftKey(recordId),
      {},
      Duration.zero,
    );
  }
}

final healthRepositoryProvider = Provider<HealthRepositoryContract>((ref) {
  return HealthRepository(
    ref.watch(dioProvider),
    ref.watch(localCacheServiceProvider),
    ref.watch(outboxServiceProvider),
  );
});
