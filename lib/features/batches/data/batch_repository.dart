import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_result.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_helpers.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/offline/local_cache_contract.dart';
import '../../../core/offline/network_errors.dart';
import '../../animals/data/animal_dto.dart';
import '../../animals/data/animal_repository.dart';
import '../../animals/data/animal_repository_contract.dart';
import '../../offline/data/local_cache_service.dart';
import '../../offline/data/outbox_item.dart';
import '../../offline/data/outbox_service.dart';
import '../../offline/offline_providers.dart';
import 'batch_api_paths.dart';
import 'batch_dto.dart';
import 'batch_repository_contract.dart';

class BatchRepository implements BatchRepositoryContract {
  BatchRepository(
    this._dio,
    this._cache,
    this._outbox,
    this._animals,
  );

  final Dio _dio;
  final LocalCacheService _cache;
  final OutboxService _outbox;
  final AnimalRepositoryContract _animals;

  bool _localOnly = false;
  Future<ApiResult<BatchPageResult>>? _listInFlight;

  String _newLocalId() => 'batch-${DateTime.now().millisecondsSinceEpoch}';

  String _newMovementId() => 'move-${DateTime.now().millisecondsSinceEpoch}';

  @override
  Future<BatchPageResult?> readCachedList() async {
    final cached = await _cache.read(LocalCacheContract.batchesListKey);
    if (cached == null) return null;
    final batches = (cached['batches'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((j) => AnimalBatch.fromJson(j, fromCache: true))
        .toList();
    return BatchPageResult(
      batches: batches,
      total: cached['total'] as int? ?? batches.length,
      page: cached['page'] as int? ?? 1,
      pageSize: cached['pageSize'] as int? ?? 20,
      hasMore: cached['hasMore'] as bool? ?? false,
      fromCache: true,
    );
  }

  Future<List<AnimalBatch>> _readAllLocal() async {
    final cached = await readCachedList();
    return cached?.batches ?? [];
  }

  Future<void> _writeAllLocal(List<AnimalBatch> batches) async {
    await _cache.write(
      LocalCacheContract.batchesListKey,
      {
        'batches': batches.map((b) => b.toJson()).toList(),
        'total': batches.length,
        'page': 1,
        'pageSize': 20,
        'hasMore': false,
      },
      LocalCacheContract.profileTtl,
    );
  }

  Future<void> _writeDetailCache(AnimalBatch batch) async {
    await _cache.write(
      LocalCacheContract.batchDetailKey(batch.id),
      {'batch': batch.toJson()},
      LocalCacheContract.profileTtl,
    );
  }

  List<AnimalBatch> _applyFilters(
    List<AnimalBatch> batches,
    String search,
    BatchFilter filter,
  ) {
    var result = batches.where((b) => b.active).toList();
    if (search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      result = result
          .where(
            (b) =>
                b.name.toLowerCase().contains(q) ||
                (b.animalType ?? '').toLowerCase().contains(q) ||
                (b.location ?? '').toLowerCase().contains(q),
          )
          .toList();
    }
    switch (filter) {
      case BatchFilter.all:
        break;
      case BatchFilter.active:
        result = result.where((b) => b.animalCount > 0).toList();
      case BatchFilter.empty:
        result = result.where((b) => b.animalCount == 0).toList();
    }
    return result;
  }

  BatchPageResult _paginate(List<AnimalBatch> batches, int page, int pageSize) {
    final start = (page - 1) * pageSize;
    if (start >= batches.length) {
      return BatchPageResult(
        batches: const [],
        total: batches.length,
        page: page,
        pageSize: pageSize,
        hasMore: false,
      );
    }
    final end = (start + pageSize).clamp(0, batches.length);
    return BatchPageResult(
      batches: batches.sublist(start, end),
      total: batches.length,
      page: page,
      pageSize: pageSize,
      hasMore: end < batches.length,
    );
  }

  Future<List<AnimalBatch>> _fetchFromApi() async {
    final data = await getJson(_dio, BatchApiPaths.batches);
    return (data['batches'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(AnimalBatch.fromJson)
        .toList();
  }

  Future<List<AnimalBatch>> _seedFromAnimalsIfEmpty(List<AnimalBatch> existing) async {
    if (existing.isNotEmpty) return existing;
    final animalsResult = await _animals.readCachedList();
    final animals = animalsResult?.animals ?? [];
    if (animals.isEmpty) return existing;

    final grouped = <String, List<AnimalProfile>>{};
    for (final animal in animals.where((a) => a.active)) {
      final key = animal.animalType ?? animal.species;
      grouped.putIfAbsent(key, () => []).add(animal);
    }

    final now = DateTime.now();
    final seeded = grouped.entries.map((entry) {
      return AnimalBatch(
        id: 'auto-${entry.key.toLowerCase()}',
        name: '${_labelForType(entry.key)} group',
        animalType: entry.key,
        animalIds: entry.value.map((a) => a.id).toList(),
        isAutoGenerated: true,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();

    if (seeded.isNotEmpty) {
      await _writeAllLocal(seeded);
    }
    return seeded;
  }

  String _labelForType(String type) {
    switch (type.toUpperCase()) {
      case 'CATTLE':
        return 'Cattle';
      case 'GOAT':
        return 'Goat';
      case 'POULTRY':
        return 'Poultry';
      case 'DOG':
        return 'Dog';
      case 'CAT':
        return 'Cat';
      default:
        return type;
    }
  }

  bool _isApiUnavailable(AppException e) {
    final message = e.message.toLowerCase();
    return message.contains('404') ||
        message.contains('not found') ||
        e.code == '404' ||
        e.code == 'NOT_FOUND';
  }

  @override
  Future<ApiResult<BatchPageResult>> listBatches({
    int page = 1,
    int pageSize = 20,
    String search = '',
    BatchFilter filter = BatchFilter.all,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _listInFlight != null) return _listInFlight!;
    final future = _loadList(
      page: page,
      pageSize: pageSize,
      search: search,
      filter: filter,
    );
    _listInFlight = future;
    try {
      return await future;
    } finally {
      _listInFlight = null;
    }
  }

  Future<ApiResult<BatchPageResult>> _loadList({
    required int page,
    required int pageSize,
    required String search,
    required BatchFilter filter,
  }) async {
    try {
      if (!_localOnly) {
        final all = await _fetchFromApi();
        await _writeAllLocal(all);
        final filtered = _applyFilters(all, search, filter);
        return ApiResult.success(_paginate(filtered, page, pageSize));
      }
      throw const AppException(message: 'Local-only mode');
    } on AppException catch (e) {
      if (!_localOnly && _isApiUnavailable(e)) {
        _localOnly = true;
      }
      var local = await _readAllLocal();
      local = await _seedFromAnimalsIfEmpty(local);
      if (local.isNotEmpty || _localOnly || isTransientNetworkError(e)) {
        final filtered = _applyFilters(local, search, filter);
        return ApiResult.success(
          _paginate(filtered, page, pageSize).copyWith(fromCache: true),
        );
      }
      return ApiResult.failure(e);
    } catch (e) {
      var local = await _readAllLocal();
      local = await _seedFromAnimalsIfEmpty(local);
      if (local.isNotEmpty) {
        final filtered = _applyFilters(local, search, filter);
        return ApiResult.success(
          _paginate(filtered, page, pageSize).copyWith(fromCache: true),
        );
      }
      return ApiResult.failure(AppException(message: 'Could not load groups', cause: e));
    }
  }

  Future<List<BatchAnimalSummary>> _resolveAnimals(List<String> ids) async {
    final cached = await _animals.readCachedList();
    final byId = {for (final a in cached?.animals ?? []) a.id: a};
    return ids.map((id) {
      final animal = byId[id];
      return BatchAnimalSummary(
        id: id,
        label: animal?.name ?? id,
        animalType: animal?.animalType,
      );
    }).toList();
  }

  @override
  Future<ApiResult<BatchDetail>> getBatch(String id, {bool forceRefresh = false}) async {
    try {
      if (!_localOnly) {
        final data = await getJson(_dio, BatchApiPaths.batch(id));
        final raw = data['batch'];
        if (raw is! Map<String, dynamic>) {
          return ApiResult.failure(const AppException(message: 'Batch not found'));
        }
        final batch = AnimalBatch.fromJson(raw);
        await _writeDetailCache(batch);
        final animals = await _resolveAnimals(batch.animalIds);
        return ApiResult.success(BatchDetail(batch: batch, animals: animals));
      }
      throw const AppException(message: 'Local-only mode');
    } on AppException catch (e) {
      if (!_localOnly && _isApiUnavailable(e)) _localOnly = true;
      final cached = await _cache.read(LocalCacheContract.batchDetailKey(id));
      AnimalBatch? batch;
      if (cached != null) {
        batch = AnimalBatch.fromJson(cached['batch'] as Map<String, dynamic>, fromCache: true);
      } else {
        final all = await _readAllLocal();
        try {
          batch = all.firstWhere((b) => b.id == id).copyWith(fromCache: true);
        } catch (_) {
          batch = null;
        }
      }
      if (batch != null) {
        final animals = await _resolveAnimals(batch.animalIds);
        return ApiResult.success(
          BatchDetail(batch: batch, animals: animals, fromCache: true),
        );
      }
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<AnimalBatch>> _persistLocalBatch(
    AnimalBatch batch, {
    required bool enqueue,
    OutboxKind? kind,
    Map<String, dynamic>? payload,
  }) async {
    final all = await _readAllLocal();
    final index = all.indexWhere((b) => b.id == batch.id);
    final updated = [...all];
    if (index >= 0) {
      updated[index] = batch;
    } else {
      updated.insert(0, batch);
    }
    await _writeAllLocal(updated);
    await _writeDetailCache(batch);

    if (enqueue && kind != null && payload != null) {
      await _enqueue(kind, payload, batch.id);
    }
    return ApiResult.success(batch);
  }

  @override
  Future<ApiResult<AnimalBatch>> createBatch(BatchInput input) async {
    final body = input.toCreateJson();
    try {
      if (!_localOnly) {
        final data = await postJson(_dio, BatchApiPaths.batches, body);
        final raw = data['batch'];
        if (raw is! Map<String, dynamic>) {
          return ApiResult.failure(const AppException(message: 'Invalid create response'));
        }
        final batch = AnimalBatch.fromJson(raw);
        await clearDraft();
        await _writeDetailCache(batch);
        final all = await _readAllLocal();
        await _writeAllLocal([batch, ...all.where((b) => b.id != batch.id)]);
        return ApiResult.success(batch);
      }
      throw const AppException(message: 'Local-only mode');
    } on AppException catch (e) {
      if (!_localOnly && _isApiUnavailable(e)) _localOnly = true;
      if (_localOnly || isTransientNetworkError(e)) {
        final now = DateTime.now();
        final batch = AnimalBatch(
          id: _newLocalId(),
          name: input.name.trim(),
          notes: input.notes,
          animalType: input.animalType,
          location: input.location,
          animalIds: input.animalIds,
          pendingSync: true,
          createdAt: now,
          updatedAt: now,
          fromCache: true,
        );
        await clearDraft();
        final result = await _persistLocalBatch(
          batch,
          enqueue: true,
          kind: OutboxKind.batchCreate,
          payload: body,
        );
        if (isTransientNetworkError(e) && !_localOnly) {
          return ApiResult.failure(
            const AppException(message: 'Saved offline — will sync when online', code: offlineQueuedCode),
          );
        }
        return result;
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<AnimalBatch>> updateBatch(String id, BatchInput input) async {
    final body = input.toPatchJson();
    try {
      if (!_localOnly) {
        final data = await patchJson(_dio, BatchApiPaths.batch(id), body);
        final raw = data['batch'];
        if (raw is! Map<String, dynamic>) {
          return ApiResult.failure(const AppException(message: 'Invalid update response'));
        }
        final batch = AnimalBatch.fromJson(raw);
        await clearDraft(batchId: id);
        return _persistLocalBatch(batch, enqueue: false);
      }
      throw const AppException(message: 'Local-only mode');
    } on AppException catch (e) {
      if (!_localOnly && _isApiUnavailable(e)) _localOnly = true;
      if (_localOnly || isTransientNetworkError(e)) {
        final existing = await _findLocalBatch(id);
        if (existing == null) {
          return ApiResult.failure(const AppException(message: 'Batch not found'));
        }
        final batch = existing.copyWith(
          name: input.name.trim(),
          notes: input.notes,
          animalType: input.animalType,
          location: input.location,
          animalIds: input.animalIds,
          pendingSync: true,
          updatedAt: DateTime.now(),
          fromCache: true,
        );
        await clearDraft(batchId: id);
        final payload = {...body, 'id': id};
        final result = await _persistLocalBatch(
          batch,
          enqueue: true,
          kind: OutboxKind.batchPatch,
          payload: payload,
        );
        if (isTransientNetworkError(e) && !_localOnly) {
          return ApiResult.failure(
            const AppException(message: 'Saved offline — will sync when online', code: offlineQueuedCode),
          );
        }
        return result;
      }
      return ApiResult.failure(e);
    }
  }

  Future<AnimalBatch?> _findLocalBatch(String id) async {
    final cached = await _cache.read(LocalCacheContract.batchDetailKey(id));
    if (cached != null) {
      return AnimalBatch.fromJson(cached['batch'] as Map<String, dynamic>);
    }
    final all = await _readAllLocal();
    try {
      return all.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ApiResult<AnimalBatch>> moveAnimals(BatchMoveInput input) async {
    final body = input.toJson();
    try {
      if (!_localOnly) {
        final data = await postJson(_dio, BatchApiPaths.move(input.fromBatchId), body);
        final raw = data['batch'];
        if (raw is! Map<String, dynamic>) {
          return ApiResult.failure(const AppException(message: 'Invalid move response'));
        }
        final batch = AnimalBatch.fromJson(raw);
        return _persistLocalBatch(batch, enqueue: false);
      }
      throw const AppException(message: 'Local-only mode');
    } on AppException catch (e) {
      if (!_localOnly && _isApiUnavailable(e)) _localOnly = true;
      if (_localOnly || isTransientNetworkError(e)) {
        return _applyLocalMove(input, enqueue: true, payload: body);
      }
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<AnimalBatch>> _applyLocalMove(
    BatchMoveInput input, {
    required bool enqueue,
    Map<String, dynamic>? payload,
  }) async {
    final from = await _findLocalBatch(input.fromBatchId);
    final to = await _findLocalBatch(input.toBatchId);
    if (from == null || to == null) {
      return ApiResult.failure(const AppException(message: 'Batch not found'));
    }

    final now = DateTime.now();
    final movement = BatchMovement(
      id: _newMovementId(),
      type: 'MOVE',
      fromBatchId: input.fromBatchId,
      toBatchId: input.toBatchId,
      animalIds: input.animalIds,
      notes: input.notes,
      at: now,
    );

    final updatedFromIds = from.animalIds.where((id) => !input.animalIds.contains(id)).toList();
    final updatedToIds = [...to.animalIds, ...input.animalIds.where((id) => !to.animalIds.contains(id))];

    final updatedFrom = from.copyWith(
      animalIds: updatedFromIds,
      movements: [...from.movements, movement],
      pendingSync: true,
      updatedAt: now,
    );
    final updatedTo = to.copyWith(
      animalIds: updatedToIds,
      movements: [...to.movements, movement],
      pendingSync: true,
      updatedAt: now,
    );

    await _persistLocalBatch(updatedFrom, enqueue: false);
    await _persistLocalBatch(
      updatedTo,
      enqueue: enqueue,
      kind: OutboxKind.batchMove,
      payload: payload,
    );
    return ApiResult.success(updatedTo);
  }

  @override
  Future<ApiResult<AnimalBatch>> mergeBatches(BatchMergeInput input) async {
    final body = input.toJson();
    try {
      if (!_localOnly) {
        final data = await postJson(_dio, BatchApiPaths.merge, body);
        final raw = data['batch'];
        if (raw is! Map<String, dynamic>) {
          return ApiResult.failure(const AppException(message: 'Invalid merge response'));
        }
        final batch = AnimalBatch.fromJson(raw);
        final all = await _readAllLocal();
        await _writeAllLocal(all.where((b) => b.id != input.sourceBatchId).toList());
        return _persistLocalBatch(batch, enqueue: false);
      }
      throw const AppException(message: 'Local-only mode');
    } on AppException catch (e) {
      if (!_localOnly && _isApiUnavailable(e)) _localOnly = true;
      if (_localOnly || isTransientNetworkError(e)) {
        return _applyLocalMerge(input, enqueue: true, payload: body);
      }
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<AnimalBatch>> _applyLocalMerge(
    BatchMergeInput input, {
    required bool enqueue,
    Map<String, dynamic>? payload,
  }) async {
    final source = await _findLocalBatch(input.sourceBatchId);
    final target = await _findLocalBatch(input.targetBatchId);
    if (source == null || target == null) {
      return ApiResult.failure(const AppException(message: 'Batch not found'));
    }

    final now = DateTime.now();
    final movement = BatchMovement(
      id: _newMovementId(),
      type: 'MERGE',
      fromBatchId: input.sourceBatchId,
      toBatchId: input.targetBatchId,
      animalIds: source.animalIds,
      at: now,
    );

    final mergedIds = [...target.animalIds, ...source.animalIds.where((id) => !target.animalIds.contains(id))];
    final merged = target.copyWith(
      animalIds: mergedIds,
      movements: [...target.movements, movement],
      pendingSync: true,
      updatedAt: now,
    );

    final all = await _readAllLocal();
    final remaining = all.where((b) => b.id != input.sourceBatchId).map((b) {
      if (b.id == merged.id) return merged;
      return b;
    }).toList();
    await _writeAllLocal(remaining);
    await _writeDetailCache(merged);

    if (enqueue && payload != null) {
      await _enqueue(OutboxKind.batchMerge, payload, input.sourceBatchId);
    }
    return ApiResult.success(merged);
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

  @override
  Future<void> saveDraft(BatchInput input, {String? batchId}) async {
    await _cache.write(
      batchId == null ? LocalCacheContract.batchDraftKey : LocalCacheContract.batchEditDraftKey(batchId),
      input.toDraftJson(),
      LocalCacheContract.profileTtl,
    );
  }

  @override
  Future<BatchInput?> readDraft({String? batchId}) async {
    final raw = await _cache.read(
      batchId == null ? LocalCacheContract.batchDraftKey : LocalCacheContract.batchEditDraftKey(batchId),
    );
    if (raw == null) return null;
    return BatchInput.fromDraftJson(raw);
  }

  @override
  Future<void> clearDraft({String? batchId}) async {
    await _cache.write(
      batchId == null ? LocalCacheContract.batchDraftKey : LocalCacheContract.batchEditDraftKey(batchId),
      {},
      Duration.zero,
    );
  }
}

final batchRepositoryProvider = Provider<BatchRepository>((ref) {
  return BatchRepository(
    ref.watch(dioProvider),
    ref.watch(localCacheServiceProvider),
    ref.watch(outboxServiceProvider),
    ref.watch(animalRepositoryProvider),
  );
});
