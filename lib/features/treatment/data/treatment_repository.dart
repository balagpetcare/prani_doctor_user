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
import 'treatment_api_paths.dart';
import 'treatment_dto.dart';
import 'treatment_repository_contract.dart';

class TreatmentRepository implements TreatmentRepositoryContract {
  TreatmentRepository(this._dio, this._cache, this._outbox);

  final Dio _dio;
  final LocalCacheService _cache;
  final OutboxService _outbox;

  Future<ApiResult<TreatmentPageResult>>? _listInFlight;

  @override
  Future<TreatmentPageResult?> readCachedList() async {
    final cached = await _cache.read(LocalCacheContract.treatmentsListKey);
    if (cached == null) return null;
    final records = (cached['records'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((j) => FarmTreatment.fromJson(j, fromCache: true))
        .toList();
    final pendingSyncCount = records.where((r) => r.pendingSync).length;
    return TreatmentPageResult(
      records: records,
      total: cached['total'] as int? ?? records.length,
      page: cached['page'] as int? ?? 1,
      limit: cached['limit'] as int? ?? 20,
      hasMore: cached['hasMore'] as bool? ?? false,
      pendingSyncCount: pendingSyncCount,
      fromCache: true,
    );
  }

  Future<void> _writeListCache(TreatmentPageResult page) async {
    await _cache.write(LocalCacheContract.treatmentsListKey, {
      'records': page.records.map((r) => r.toJson()).toList(),
      'total': page.total,
      'page': page.page,
      'limit': page.limit,
      'hasMore': page.hasMore,
    }, LocalCacheContract.profileTtl);
  }

  TreatmentPageResult _parseListPage(Map<String, dynamic> data) {
    final records = (data['records'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(FarmTreatment.fromJson)
        .toList();
    return TreatmentPageResult(
      records: records,
      total: data['total'] as int? ?? records.length,
      page: data['page'] as int? ?? 1,
      limit: data['limit'] as int? ?? 20,
      hasMore: data['hasMore'] as bool? ?? false,
      pendingSyncCount: records.where((r) => r.pendingSync).length,
    );
  }

  @override
  Future<ApiResult<TreatmentPageResult>> listRecords({
    String? animalId,
    TreatmentStatus? status,
    String search = '',
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _listInFlight != null) return _listInFlight!;
    final future = _loadList(
      animalId: animalId,
      status: status,
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

  Future<ApiResult<TreatmentPageResult>> _loadList({
    String? animalId,
    TreatmentStatus? status,
    required String search,
    required int page,
    required int limit,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (animalId != null && animalId.isNotEmpty) 'animalId': animalId,
        if (status != null) 'status': status.apiValue,
        if (search.trim().isNotEmpty) 'search': search.trim(),
      };
      final data = await getJson(
        _dio,
        TreatmentApiPaths.treatments,
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

  Future<void> _optimisticUpsert(FarmTreatment record) async {
    final cached = await readCachedList();
    final existing = cached?.records ?? [];
    final updated = [record, ...existing.where((r) => r.id != record.id)];
    await _writeListCache(
      TreatmentPageResult(
        records: updated,
        total: updated.length,
        page: 1,
        limit: 20,
        hasMore: false,
      ),
    );
    await _cache.write(
      LocalCacheContract.treatmentDetailKey(record.id),
      {'record': record.toJson()},
      LocalCacheContract.profileTtl,
    );
  }

  Future<void> _optimisticRemove(String id) async {
    final cached = await readCachedList();
    if (cached == null) return;
    final updated = cached.records.where((r) => r.id != id).toList();
    await _writeListCache(
      TreatmentPageResult(
        records: updated,
        total: updated.length,
        page: cached.page,
        limit: cached.limit,
        hasMore: cached.hasMore,
      ),
    );
  }

  @override
  Future<ApiResult<FarmTreatment>> getRecord(String id) async {
    try {
      final data = await getJson(_dio, TreatmentApiPaths.record(id));
      final raw = data['record'];
      if (raw is! Map<String, dynamic>) {
        return const ApiResult.failure(
          AppException(message: 'Record not found'),
        );
      }
      final record = FarmTreatment.fromJson(raw);
      await _cache.write(LocalCacheContract.treatmentDetailKey(id), {
        'record': record.toJson(),
      }, LocalCacheContract.profileTtl);
      return ApiResult.success(record);
    } on AppException catch (e) {
      final cached = await _cache.read(
        LocalCacheContract.treatmentDetailKey(id),
      );
      if (cached != null) {
        return ApiResult.success(
          FarmTreatment.fromJson(
            cached['record'] as Map<String, dynamic>,
            fromCache: true,
          ),
        );
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<FarmTreatment>> createRecord(TreatmentInput input) async {
    final body = input.toCreateJson();
    final tempId = 'local-treatment-${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = FarmTreatment(
      id: tempId,
      customerId: '',
      farmRef: input.farmRef,
      animalId: input.animalId,
      title: input.title,
      diagnosis: input.diagnosis,
      prescription: input.prescription,
      medicines: input.medicines,
      startDate: input.startDate,
      endDate: input.endDate,
      status: input.status,
      notes: input.notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      pendingSync: true,
      fromCache: true,
    );
    await _optimisticUpsert(optimistic);

    try {
      final data = await postJson(_dio, TreatmentApiPaths.treatments, body);
      final raw = data['record'];
      if (raw is! Map<String, dynamic>) {
        return const ApiResult.failure(
          AppException(message: 'Invalid create response'),
        );
      }
      final record = FarmTreatment.fromJson(raw);
      await _optimisticUpsert(record);
      await clearDraft();
      return ApiResult.success(record);
    } on AppException catch (e) {
      if (isTransientNetworkError(e)) {
        await _enqueue(OutboxKind.treatmentCreate, body, tempId);
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
  Future<ApiResult<FarmTreatment>> updateRecord(
    String id,
    TreatmentInput input,
  ) async {
    final body = input.toPatchJson();
    final existingResult = await getRecord(id);
    if (existingResult case ApiSuccess(data: final existing)) {
      await _optimisticUpsert(
        existing.copyWith(
          farmRef: input.farmRef,
          animalId: input.animalId,
          title: input.title,
          diagnosis: input.diagnosis,
          prescription: input.prescription,
          medicines: input.medicines,
          startDate: input.startDate,
          endDate: input.endDate,
          status: input.status,
          notes: input.notes,
          pendingSync: true,
          updatedAt: DateTime.now(),
        ),
      );
    }

    try {
      final data = await patchJson(_dio, TreatmentApiPaths.record(id), body);
      final raw = data['record'];
      if (raw is! Map<String, dynamic>) {
        return const ApiResult.failure(
          AppException(message: 'Invalid update response'),
        );
      }
      final record = FarmTreatment.fromJson(raw);
      await _optimisticUpsert(record);
      await clearDraft(recordId: id);
      return ApiResult.success(record);
    } on AppException catch (e) {
      if (isTransientNetworkError(e)) {
        await _enqueue(OutboxKind.treatmentPatch, {...body, 'id': id}, id);
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
      await deleteJson(_dio, TreatmentApiPaths.record(id));
      return const ApiResult.success(null);
    } on AppException catch (e) {
      if (isTransientNetworkError(e)) {
        await _enqueue(OutboxKind.treatmentDelete, {'id': id}, id);
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
  Future<void> saveDraft(TreatmentInput input, {String? recordId}) async {
    await _cache.write(
      recordId == null
          ? LocalCacheContract.treatmentDraftKey
          : LocalCacheContract.treatmentEditDraftKey(recordId),
      input.toDraftJson(),
      LocalCacheContract.profileTtl,
    );
  }

  @override
  Future<TreatmentInput?> readDraft({String? recordId}) async {
    final raw = await _cache.read(
      recordId == null
          ? LocalCacheContract.treatmentDraftKey
          : LocalCacheContract.treatmentEditDraftKey(recordId),
    );
    if (raw == null || raw.isEmpty) return null;
    return TreatmentInput.fromDraftJson(raw);
  }

  @override
  Future<void> clearDraft({String? recordId}) async {
    await _cache.write(
      recordId == null
          ? LocalCacheContract.treatmentDraftKey
          : LocalCacheContract.treatmentEditDraftKey(recordId),
      {},
      Duration.zero,
    );
  }
}

final treatmentRepositoryProvider = Provider<TreatmentRepositoryContract>((
  ref,
) {
  return TreatmentRepository(
    ref.watch(dioProvider),
    ref.watch(localCacheServiceProvider),
    ref.watch(outboxServiceProvider),
  );
});
