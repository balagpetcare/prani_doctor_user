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
import 'vaccine_api_paths.dart';
import 'vaccine_dto.dart';
import 'vaccine_repository_contract.dart';

class VaccineRepository implements VaccineRepositoryContract {
  VaccineRepository(this._dio, this._cache, this._outbox);

  final Dio _dio;
  final LocalCacheService _cache;
  final OutboxService _outbox;

  Future<ApiResult<VaccinePageResult>>? _listInFlight;

  @override
  Future<VaccinePageResult?> readCachedList() async {
    final cached = await _cache.read(LocalCacheContract.vaccinesListKey);
    if (cached == null) return null;
    final records = (cached['records'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((j) => VaccineRecord.fromJson(j, fromCache: true))
        .toList();
    final pendingSyncCount = records.where((r) => r.pendingSync).length;
    return VaccinePageResult(
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
  Future<VaccineRemindersData?> readCachedReminders() async {
    final cached = await _cache.read(LocalCacheContract.vaccineRemindersKey);
    if (cached == null) return null;
    return _parseReminders(cached, fromCache: true);
  }

  VaccineRemindersData _parseReminders(
    Map<String, dynamic> reminders, {
    bool fromCache = false,
  }) {
    return VaccineRemindersData(
      overdue: (reminders['overdue'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((j) => VaccineRecord.fromJson(j, fromCache: fromCache))
          .toList(),
      upcoming: (reminders['upcoming'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((j) => VaccineRecord.fromJson(j, fromCache: fromCache))
          .toList(),
      nextDue: reminders['nextDue'] is Map<String, dynamic>
          ? VaccineRecord.fromJson(
              reminders['nextDue'] as Map<String, dynamic>,
              fromCache: fromCache,
            )
          : null,
      fromCache: fromCache,
    );
  }

  Future<void> _writeListCache(VaccinePageResult page) async {
    await _cache.write(LocalCacheContract.vaccinesListKey, {
      'records': page.records.map((r) => r.toJson()).toList(),
      'total': page.total,
      'page': page.page,
      'limit': page.limit,
      'hasMore': page.hasMore,
    }, LocalCacheContract.profileTtl);
  }

  VaccinePageResult _parseListPage(Map<String, dynamic> data) {
    final records = (data['records'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(VaccineRecord.fromJson)
        .toList();
    return VaccinePageResult(
      records: records,
      total: data['total'] as int? ?? records.length,
      page: data['page'] as int? ?? 1,
      limit: data['limit'] as int? ?? 20,
      hasMore: data['hasMore'] as bool? ?? false,
      pendingSyncCount: records.where((r) => r.pendingSync).length,
    );
  }

  @override
  Future<ApiResult<VaccinePageResult>> listRecords({
    String? animalId,
    VaccineStatus? status,
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _listInFlight != null) return _listInFlight!;
    final future = _loadList(
      animalId: animalId,
      status: status,
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

  Future<ApiResult<VaccinePageResult>> _loadList({
    String? animalId,
    VaccineStatus? status,
    required int page,
    required int limit,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (animalId != null && animalId.isNotEmpty) 'animalId': animalId,
        if (status != null) 'status': status.apiValue,
      };
      final data = await getJson(
        _dio,
        VaccineApiPaths.vaccines,
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

  @override
  Future<ApiResult<VaccineRemindersData>> getReminders({
    bool forceRefresh = false,
  }) async {
    try {
      final data = await getJson(_dio, VaccineApiPaths.reminders);
      final raw = data['reminders'];
      if (raw is! Map<String, dynamic>) {
        return const ApiResult.failure(
          AppException(message: 'Invalid reminders response'),
        );
      }
      await _cache.write(
        LocalCacheContract.vaccineRemindersKey,
        raw,
        LocalCacheContract.profileTtl,
      );
      return ApiResult.success(_parseReminders(raw));
    } on AppException catch (e) {
      final cached = await readCachedReminders();
      if (cached != null) return ApiResult.success(cached);
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

  Future<void> _optimisticUpsert(VaccineRecord record) async {
    final cached = await readCachedList();
    final existing = cached?.records ?? [];
    final updated = [record, ...existing.where((r) => r.id != record.id)];
    await _writeListCache(
      VaccinePageResult(
        records: updated,
        total: updated.length,
        page: 1,
        limit: 20,
        hasMore: false,
      ),
    );
    await _cache.write(
      LocalCacheContract.vaccineDetailKey(record.id),
      {'record': record.toJson()},
      LocalCacheContract.profileTtl,
    );
  }

  Future<void> _optimisticRemove(String id) async {
    final cached = await readCachedList();
    if (cached == null) return;
    final updated = cached.records.where((r) => r.id != id).toList();
    await _writeListCache(
      VaccinePageResult(
        records: updated,
        total: updated.length,
        page: cached.page,
        limit: cached.limit,
        hasMore: cached.hasMore,
      ),
    );
  }

  @override
  Future<ApiResult<VaccineRecord>> getRecord(String id) async {
    try {
      final data = await getJson(_dio, VaccineApiPaths.record(id));
      final raw = data['record'];
      if (raw is! Map<String, dynamic>) {
        return const ApiResult.failure(
          AppException(message: 'Record not found'),
        );
      }
      final record = VaccineRecord.fromJson(raw);
      await _cache.write(LocalCacheContract.vaccineDetailKey(id), {
        'record': record.toJson(),
      }, LocalCacheContract.profileTtl);
      return ApiResult.success(record);
    } on AppException catch (e) {
      final cached = await _cache.read(LocalCacheContract.vaccineDetailKey(id));
      if (cached != null) {
        return ApiResult.success(
          VaccineRecord.fromJson(
            cached['record'] as Map<String, dynamic>,
            fromCache: true,
          ),
        );
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<VaccineRecord>> createRecord(VaccineInput input) async {
    final body = input.toCreateJson();
    final tempId = 'local-vaccine-${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = VaccineRecord(
      id: tempId,
      customerId: '',
      farmRef: input.farmRef,
      animalId: input.animalId,
      vaccineName: input.vaccineName,
      vaccineType: input.vaccineType,
      scheduledDate: input.scheduledDate,
      administeredDate: input.administeredDate,
      nextDueDate: input.nextDueDate,
      status: input.administeredDate != null
          ? VaccineStatus.completed
          : VaccineStatus.scheduled,
      batchNumber: input.batchNumber,
      notes: input.notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      pendingSync: true,
      fromCache: true,
    );
    await _optimisticUpsert(optimistic);

    try {
      final data = await postJson(_dio, VaccineApiPaths.vaccines, body);
      final raw = data['record'];
      if (raw is! Map<String, dynamic>) {
        return const ApiResult.failure(
          AppException(message: 'Invalid create response'),
        );
      }
      final record = VaccineRecord.fromJson(raw);
      await _optimisticUpsert(record);
      await clearDraft();
      return ApiResult.success(record);
    } on AppException catch (e) {
      if (isTransientNetworkError(e)) {
        await _enqueue(OutboxKind.vaccineCreate, body, tempId);
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
  Future<ApiResult<VaccineRecord>> updateRecord(
    String id,
    VaccineInput input,
  ) async {
    final body = input.toPatchJson();
    final existingResult = await getRecord(id);
    if (existingResult case ApiSuccess(data: final existing)) {
      await _optimisticUpsert(
        existing.copyWith(
          farmRef: input.farmRef,
          animalId: input.animalId,
          vaccineName: input.vaccineName,
          vaccineType: input.vaccineType,
          scheduledDate: input.scheduledDate,
          administeredDate: input.administeredDate,
          nextDueDate: input.nextDueDate,
          batchNumber: input.batchNumber,
          notes: input.notes,
          pendingSync: true,
          updatedAt: DateTime.now(),
        ),
      );
    }

    try {
      final data = await patchJson(_dio, VaccineApiPaths.record(id), body);
      final raw = data['record'];
      if (raw is! Map<String, dynamic>) {
        return const ApiResult.failure(
          AppException(message: 'Invalid update response'),
        );
      }
      final record = VaccineRecord.fromJson(raw);
      await _optimisticUpsert(record);
      await clearDraft(recordId: id);
      return ApiResult.success(record);
    } on AppException catch (e) {
      if (isTransientNetworkError(e)) {
        await _enqueue(OutboxKind.vaccinePatch, {...body, 'id': id}, id);
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
      await deleteJson(_dio, VaccineApiPaths.record(id));
      return const ApiResult.success(null);
    } on AppException catch (e) {
      if (isTransientNetworkError(e)) {
        await _enqueue(OutboxKind.vaccineDelete, {'id': id}, id);
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
  Future<void> saveDraft(VaccineInput input, {String? recordId}) async {
    await _cache.write(
      recordId == null
          ? LocalCacheContract.vaccineDraftKey
          : LocalCacheContract.vaccineEditDraftKey(recordId),
      input.toDraftJson(),
      LocalCacheContract.profileTtl,
    );
  }

  @override
  Future<VaccineInput?> readDraft({String? recordId}) async {
    final raw = await _cache.read(
      recordId == null
          ? LocalCacheContract.vaccineDraftKey
          : LocalCacheContract.vaccineEditDraftKey(recordId),
    );
    if (raw == null || raw.isEmpty) return null;
    return VaccineInput.fromDraftJson(raw);
  }

  @override
  Future<void> clearDraft({String? recordId}) async {
    await _cache.write(
      recordId == null
          ? LocalCacheContract.vaccineDraftKey
          : LocalCacheContract.vaccineEditDraftKey(recordId),
      {},
      Duration.zero,
    );
  }
}

final vaccineRepositoryProvider = Provider<VaccineRepositoryContract>((ref) {
  return VaccineRepository(
    ref.watch(dioProvider),
    ref.watch(localCacheServiceProvider),
    ref.watch(outboxServiceProvider),
  );
});
