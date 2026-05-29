import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_result.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_helpers.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/offline/local_cache_contract.dart';
import '../../animals/data/animal_dto.dart';
import '../../feed/data/feed_dto.dart';
import '../../offline/data/local_cache_service.dart';
import '../../offline/data/outbox_item.dart';
import '../../offline/data/outbox_service.dart';
import '../../offline/offline_providers.dart';
import 'fattening_api_paths.dart';
import 'fattening_batch_dto.dart';
import 'fattening_feed_dto.dart';
import 'fattening_qurbani_dto.dart';
import 'fattening_roi_dto.dart';
import 'fattening_repository_contract.dart';
import '../weight/data/weight_dto.dart';

class FatteningRepository implements FatteningRepositoryContract {
  FatteningRepository(this._dio, this._cache, this._outbox);

  final Dio _dio;
  final LocalCacheService _cache;
  final OutboxService _outbox;

  Future<ApiResult<FatteningBatchPageResult>>? _listInFlight;

  String _listKey(String farmId) =>
      LocalCacheContract.fatteningBatchesListKey(farmId);

  String _newLocalId() =>
      'fattening-batch-${DateTime.now().millisecondsSinceEpoch}';

  @override
  Future<FatteningBatchPageResult?> readCachedList(String farmId) async {
    final cached = await _cache.read(_listKey(farmId));
    if (cached == null) return null;
    final batches = (cached['batches'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((j) => FatteningBatch.fromJson(j, fromCache: true))
        .toList();
    return FatteningBatchPageResult(
      batches: batches,
      total: cached['total'] as int? ?? batches.length,
      page: cached['page'] as int? ?? 1,
      pageSize: cached['pageSize'] as int? ?? 20,
      hasMore: cached['hasMore'] as bool? ?? false,
      fromCache: true,
      pendingSyncCount:
          cached['pendingSyncCount'] as int? ??
          batches.where((b) => b.pendingSync).length,
    );
  }

  @override
  Future<FatteningBatchDetail?> readCachedDetail(String batchId) async {
    final cached = await _cache.read(
      LocalCacheContract.fatteningBatchDetailKey(batchId),
    );
    if (cached == null) return null;
    final batchRaw = cached['batch'];
    if (batchRaw is! Map<String, dynamic>) return null;
    final animals = (cached['animals'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((j) => AnimalProfile.fromJson(j, fromCache: true))
        .toList();
    return FatteningBatchDetail(
      batch: FatteningBatch.fromJson(batchRaw, fromCache: true),
      animals: animals,
      fromCache: true,
    );
  }

  Future<void> _writeListCache(
    String farmId,
    FatteningBatchPageResult page,
  ) async {
    await _cache.write(_listKey(farmId), {
      'batches': page.batches.map((b) => b.toJson()).toList(),
      'total': page.total,
      'page': page.page,
      'pageSize': page.pageSize,
      'hasMore': page.hasMore,
      'pendingSyncCount': page.pendingSyncCount,
    }, LocalCacheContract.profileTtl);
  }

  Future<void> _writeDetailCache(FatteningBatchDetail detail) async {
    await _cache.write(
      LocalCacheContract.fatteningBatchDetailKey(detail.batch.id),
      {
        'batch': detail.batch.toJson(),
        'animals': detail.animals.map((a) => a.toJson()).toList(),
      },
      LocalCacheContract.profileTtl,
    );
  }

  FatteningBatchPageResult _parseListPage(Map<String, dynamic> data) {
    final batches = (data['batches'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(FatteningBatch.fromJson)
        .toList();
    return FatteningBatchPageResult(
      batches: batches,
      total: data['total'] as int? ?? batches.length,
      page: data['page'] as int? ?? 1,
      pageSize: data['pageSize'] as int? ?? 20,
      hasMore: data['hasMore'] as bool? ?? false,
      pendingSyncCount: batches.where((b) => b.pendingSync).length,
    );
  }

  FatteningBatchDetail _parseDetail(Map<String, dynamic> data) {
    final batchRaw = data['batch'];
    if (batchRaw is! Map<String, dynamic>) {
      throw const AppException(message: 'Invalid batch response');
    }
    final animals = (data['animals'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(AnimalProfile.fromJson)
        .toList();
    return FatteningBatchDetail(
      batch: FatteningBatch.fromJson(batchRaw),
      animals: animals,
    );
  }

  Future<void> _enqueue(
    OutboxKind kind,
    Map<String, dynamic> payload,
    String keySuffix, {
    bool stableIdempotency = false,
  }) async {
    final sequence = (await _outbox.listAll()).length + 1;
    final idempotencyKey = stableIdempotency
        ? '${kind.apiValue}-$keySuffix'
        : '${kind.apiValue}-$keySuffix-$sequence';
    await _outbox.enqueue(
      OutboxItem(
        idempotencyKey: idempotencyKey,
        kind: kind,
        payload: payload,
        clientSequence: sequence,
        attemptCount: 0,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  Future<void> _upsertListBatch(String farmId, FatteningBatch batch) async {
    final cached = await readCachedList(farmId);
    final existing = cached?.batches ?? [];
    final updated = [batch, ...existing.where((b) => b.id != batch.id)];
    await _writeListCache(
      farmId,
      FatteningBatchPageResult(
        batches: updated,
        total: updated.length,
        page: 1,
        pageSize: 20,
        hasMore: false,
        pendingSyncCount: updated.where((b) => b.pendingSync).length,
      ),
    );
    final detailCached = await readCachedDetail(batch.id);
    if (detailCached == null) {
      await _writeDetailCache(
        FatteningBatchDetail(batch: batch, animals: const [], fromCache: true),
      );
    } else {
      await _writeDetailCache(
        FatteningBatchDetail(
          batch: batch,
          animals: detailCached.animals,
          fromCache: detailCached.fromCache || batch.pendingSync,
        ),
      );
    }
  }

  FatteningBatchPageResult _filterPageByStatus(
    FatteningBatchPageResult page,
    FatteningBatchStatus? status,
  ) {
    if (status == null) return page;
    final batches =
        page.batches.where((batch) => batch.status == status).toList();
    return FatteningBatchPageResult(
      batches: batches,
      total: batches.length,
      page: page.page,
      pageSize: page.pageSize,
      hasMore: page.hasMore,
      pendingSyncCount: batches.where((b) => b.pendingSync).length,
      fromCache: page.fromCache,
    );
  }

  @override
  Future<ApiResult<FatteningBatchPageResult>> listBatches({
    required String farmId,
    FatteningBatchStatus? status,
    int page = 1,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && page == 1 && _listInFlight != null) {
      return _listInFlight!;
    }
    final future = _loadList(
      farmId: farmId,
      status: status,
      page: page,
    );
    if (page == 1) _listInFlight = future;
    try {
      return await future;
    } finally {
      if (page == 1) _listInFlight = null;
    }
  }

  Future<ApiResult<FatteningBatchPageResult>> _loadList({
    required String farmId,
    FatteningBatchStatus? status,
    required int page,
  }) async {
    try {
      final query = <String, dynamic>{
        'farmId': farmId,
        'page': page,
        'pageSize': 20,
        if (status != null) 'status': status.apiValue,
      };
      final data = await getJson(
        _dio,
        FatteningApiPaths.batches,
        queryParameters: query,
      );
      final pageResult = _parseListPage(data);
      if (page == 1) await _writeListCache(farmId, pageResult);
      return ApiResult.success(pageResult);
    } on AppException catch (e) {
      if (page == 1) {
        final cached = await readCachedList(farmId);
        if (cached != null) {
          return ApiResult.success(_filterPageByStatus(cached, status));
        }
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<FatteningBatchDetail>> getBatch(
    String batchId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await readCachedDetail(batchId);
      if (cached != null) return ApiResult.success(cached);
    }
    try {
      final data = await getJson(_dio, FatteningApiPaths.batch(batchId));
      final detail = _parseDetail(data);
      await _writeDetailCache(detail);
      return ApiResult.success(detail);
    } on AppException catch (e) {
      final cached = await readCachedDetail(batchId);
      if (cached != null) return ApiResult.success(cached);
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<FatteningBatch>> createBatch(
    FatteningBatchInput input,
  ) async {
    final body = input.toCreateJson();
    final tempId = _newLocalId();
    final optimistic = FatteningBatch(
      id: tempId,
      farmId: input.farmId,
      name: input.name.trim(),
      goalType: input.goalType,
      goal: input.goal?.trim(),
      targetDate: input.targetDate,
      status: FatteningBatchStatus.draft,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      pendingSync: true,
      fromCache: true,
    );
    await _upsertListBatch(input.farmId, optimistic);
    await _writeDetailCache(
      FatteningBatchDetail(
        batch: optimistic,
        animals: const [],
        fromCache: true,
      ),
    );

    try {
      final data = await postJson(_dio, FatteningApiPaths.batches, body);
      final raw = data['batch'];
      if (raw is! Map<String, dynamic>) {
        return const ApiResult.failure(
          AppException(message: 'Invalid create response'),
        );
      }
      final batch = FatteningBatch.fromJson(raw);
      await _upsertListBatch(input.farmId, batch);
      await _writeDetailCache(
        FatteningBatchDetail(batch: batch, animals: const []),
      );
      return ApiResult.success(batch);
    } on AppException {
      await _enqueue(
        OutboxKind.fatteningBatchCreate,
        {...body, 'clientId': tempId},
        tempId,
      );
      return ApiResult.success(optimistic);
    }
  }

  @override
  Future<ApiResult<FatteningBatchDetail>> addAnimals(
    String batchId,
    List<String> animalIds,
  ) async {
    final body = {'animalIds': animalIds};
    final cached = await readCachedDetail(batchId);
    if (cached != null) {
      final mergedIds = {
        ...cached.animals.map((a) => a.id),
        ...animalIds,
      };
      final optimisticAnimals = cached.animals
          .where((a) => mergedIds.contains(a.id))
          .toList();
      final optimistic = FatteningBatchDetail(
        batch: cached.batch.copyWith(
          animalCount: mergedIds.length,
          pendingSync: true,
          updatedAt: DateTime.now(),
        ),
        animals: optimisticAnimals,
        fromCache: true,
      );
      await _writeDetailCache(optimistic);
      if (cached.batch.farmId.isNotEmpty) {
        await _upsertListBatch(cached.batch.farmId, optimistic.batch);
      }
    }

    try {
      final data = await postJson(
        _dio,
        FatteningApiPaths.animals(batchId),
        body,
      );
      final detail = _parseDetail(data);
      await _writeDetailCache(detail);
      await _upsertListBatch(detail.batch.farmId, detail.batch);
      return ApiResult.success(detail);
    } on AppException catch (e) {
      await _enqueue(
        OutboxKind.fatteningBatchAddAnimals,
        {'batchId': batchId, ...body},
        batchId,
      );
      final fallback = await readCachedDetail(batchId);
      if (fallback != null) return ApiResult.success(fallback);
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<FatteningBatchDetail>> startBatch(
    String batchId, {
    DateTime? startDate,
  }) async {
    final body = <String, dynamic>{
      if (startDate != null)
        'startDate':
            '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
    };
    try {
      final data = await postJson(
        _dio,
        FatteningApiPaths.start(batchId),
        body,
      );
      final detail = _parseDetail(data);
      await _writeDetailCache(detail);
      await _upsertListBatch(detail.batch.farmId, detail.batch);
      return ApiResult.success(detail);
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }

  WeightHistoryResult _parseWeightHistory(Map<String, dynamic> data) {
    final records = (data['records'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(WeightRecord.fromJson)
        .toList();
    final progress = (data['progress'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(AnimalWeightProgress.fromJson)
        .toList();
    final growth = (data['growth'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(BatchWeightGrowthPoint.fromJson)
        .toList();
    return WeightHistoryResult(
      records: records,
      progress: progress,
      growth: growth,
      total: data['total'] as int? ?? records.length,
      page: data['page'] as int? ?? 1,
      pageSize: data['pageSize'] as int? ?? 50,
      hasMore: data['hasMore'] as bool? ?? false,
      totalGainKg: data['totalGainKg'] == null
          ? null
          : double.tryParse(data['totalGainKg'].toString()),
      avgCurrentWeightKg: data['avgCurrentWeightKg'] == null
          ? null
          : double.tryParse(data['avgCurrentWeightKg'].toString()),
    );
  }

  BatchWeightProgress _parseBatchProgress(Map<String, dynamic> data) {
    final raw = data['progress'] as Map<String, dynamic>? ?? data;
    return BatchWeightProgress.fromJson(raw);
  }

  Future<void> _writeWeightHistoryCache(
    String batchId,
    WeightHistoryResult result,
  ) async {
    await _cache.write(
      LocalCacheContract.fatteningWeightHistoryKey(batchId),
      {
        'records': result.records.map((r) => r.toJson()).toList(),
        'progress': result.progress
            .map(
              (p) => {
                'animalId': p.animalId,
                'animalName': p.animalName,
                'initialWeightKg': p.initialWeightKg,
                'currentWeightKg': p.currentWeightKg,
                'gainKg': p.gainKg,
                'recordCount': p.recordCount,
                'lastRecordedOn': p.lastRecordedOn,
              },
            )
            .toList(),
        'growth': result.growth
            .map(
              (g) => {
                'recordedOn': g.recordedOn,
                'totalWeightKg': g.totalWeightKg,
                'avgWeightKg': g.avgWeightKg,
              },
            )
            .toList(),
        if (result.totalGainKg != null) 'totalGainKg': result.totalGainKg,
        if (result.avgCurrentWeightKg != null)
          'avgCurrentWeightKg': result.avgCurrentWeightKg,
        'total': result.total,
        'page': result.page,
        'pageSize': result.pageSize,
        'hasMore': result.hasMore,
      },
      LocalCacheContract.profileTtl,
    );
  }

  @override
  Future<WeightHistoryResult?> readCachedWeightHistory(String batchId) async {
    final cached = await _cache.read(
      LocalCacheContract.fatteningWeightHistoryKey(batchId),
    );
    if (cached == null) return null;
    final records = (cached['records'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((j) => WeightRecord.fromJson(j, fromCache: true))
        .toList();
    final progress = (cached['progress'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(AnimalWeightProgress.fromJson)
        .toList();
    final growth = (cached['growth'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(BatchWeightGrowthPoint.fromJson)
        .toList();
    return WeightHistoryResult(
      records: records,
      progress: progress,
      growth: growth,
      total: cached['total'] as int? ?? records.length,
      page: cached['page'] as int? ?? 1,
      pageSize: cached['pageSize'] as int? ?? 50,
      hasMore: cached['hasMore'] as bool? ?? false,
      totalGainKg: cached['totalGainKg'] == null
          ? null
          : double.tryParse(cached['totalGainKg'].toString()),
      avgCurrentWeightKg: cached['avgCurrentWeightKg'] == null
          ? null
          : double.tryParse(cached['avgCurrentWeightKg'].toString()),
      fromCache: true,
    );
  }

  Future<void> _writeBatchProgressCache(
    String batchId,
    BatchWeightProgress progress,
  ) async {
    await _cache.write(
      LocalCacheContract.fatteningBatchProgressKey(batchId),
      {
        'batchId': progress.batchId,
        'progress': progress.progress
            .map(
              (p) => {
                'animalId': p.animalId,
                'animalName': p.animalName,
                'initialWeightKg': p.initialWeightKg,
                'currentWeightKg': p.currentWeightKg,
                'gainKg': p.gainKg,
                'recordCount': p.recordCount,
                'lastRecordedOn': p.lastRecordedOn,
              },
            )
            .toList(),
        'growth': progress.growth
            .map(
              (g) => {
                'recordedOn': g.recordedOn,
                'totalWeightKg': g.totalWeightKg,
                'avgWeightKg': g.avgWeightKg,
              },
            )
            .toList(),
        if (progress.totalGainKg != null) 'totalGainKg': progress.totalGainKg,
        if (progress.avgCurrentWeightKg != null)
          'avgCurrentWeightKg': progress.avgCurrentWeightKg,
      },
      LocalCacheContract.profileTtl,
    );
  }

  @override
  Future<BatchWeightProgress?> readCachedBatchProgress(String batchId) async {
    final cached = await _cache.read(
      LocalCacheContract.fatteningBatchProgressKey(batchId),
    );
    if (cached == null) return null;
    return BatchWeightProgress.fromJson({...cached, 'fromCache': true});
  }

  @override
  Future<ApiResult<BatchWeightProgress>> getBatchProgress(String batchId) async {
    try {
      final data = await getJson(
        _dio,
        FatteningApiPaths.batchProgress(batchId),
      );
      final progress = _parseBatchProgress(data);
      await _writeBatchProgressCache(batchId, progress);
      return ApiResult.success(progress);
    } on AppException catch (e) {
      final cached = await readCachedBatchProgress(batchId);
      if (cached != null) return ApiResult.success(cached);
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<WeightHistoryResult>> getWeightHistory({
    required String batchId,
    String? animalId,
    bool forceRefresh = false,
  }) async {
    try {
      final data = await getJson(
        _dio,
        FatteningApiPaths.weightHistory,
        queryParameters: {
          'batchId': batchId,
          if (animalId != null) 'animalId': animalId,
          'page': 1,
          'pageSize': 50,
        },
      );
      final result = _parseWeightHistory(data);
      await _writeWeightHistoryCache(batchId, result);
      return ApiResult.success(result);
    } on AppException catch (e) {
      final cached = await readCachedWeightHistory(batchId);
      if (cached != null) return ApiResult.success(cached);
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<WeightRecord>> createWeightRecord(
    WeightRecordInput input,
  ) async {
    final body = input.toJson();
    final tempId = input.clientRecordId ??
        'weight-${DateTime.now().millisecondsSinceEpoch}';
    final at = input.recordedAt ?? DateTime.now();
    final on = input.recordedOn ??
        '${at.toUtc().year.toString().padLeft(4, '0')}-'
        '${at.toUtc().month.toString().padLeft(2, '0')}-'
        '${at.toUtc().day.toString().padLeft(2, '0')}';
    final optimistic = WeightRecord(
      id: tempId,
      animalId: input.animalId,
      batchId: input.batchId,
      weightKg: input.weightKg.toString(),
      recordedAt: at,
      recordedOn: on,
      method: input.method,
      note: input.note,
      photoUrl: input.photoUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      pendingSync: true,
      fromCache: true,
    );

    final cached = await readCachedWeightHistory(input.batchId);
    if (cached != null) {
      await _writeWeightHistoryCache(
        input.batchId,
        WeightHistoryResult(
          records: [optimistic, ...cached.records],
          progress: cached.progress,
          growth: cached.growth,
          total: cached.total + 1,
          page: cached.page,
          pageSize: cached.pageSize,
          hasMore: cached.hasMore,
          fromCache: true,
        ),
      );
    }

    try {
      final data = await postJson(_dio, FatteningApiPaths.weight, body);
      final raw = data['record'];
      if (raw is! Map<String, dynamic>) {
        return const ApiResult.failure(
          AppException(message: 'Invalid weight response'),
        );
      }
      final record = WeightRecord.fromJson(raw);
      await getWeightHistory(batchId: input.batchId);
      await getBatchProgress(input.batchId);
      return ApiResult.success(record);
    } on AppException catch (e) {
      if (e.code == 'DUPLICATE_WEIGHT_DAY') {
        try {
          await getWeightHistory(batchId: input.batchId);
          await getBatchProgress(input.batchId);
        } catch (_) {}
        return ApiResult.failure(e);
      }
      final outboxKey = input.clientRecordId ??
          'weight-${input.batchId}-${input.animalId}-$on';
      await _enqueue(
        OutboxKind.fatteningWeightCreate,
        body,
        outboxKey,
        stableIdempotency: true,
      );
      return ApiResult.success(optimistic);
    }
  }

  @override
  Future<BatchFeedDashboard?> readCachedFeedDashboard(String batchId) async {
    final cached = await _cache.read(
      LocalCacheContract.fatteningFeedDashboardKey(batchId),
    );
    if (cached == null) return null;
    return BatchFeedDashboard.fromJson({...cached, 'fromCache': true});
  }

  Future<void> _writeFeedDashboardCache(
    String batchId,
    BatchFeedDashboard dashboard,
  ) async {
    await _cache.write(
      LocalCacheContract.fatteningFeedDashboardKey(batchId),
      {
        'batchId': dashboard.batchId,
        if (dashboard.plan != null)
          'plan': {
            'id': dashboard.plan!.id,
            'batchId': dashboard.plan!.batchId,
            'mode': dashboard.plan!.mode.apiValue,
            if (dashboard.plan!.dailyAmountKg != null)
              'dailyAmountKg': dashboard.plan!.dailyAmountKg.toString(),
            if (dashboard.plan!.dailyCostBdt != null)
              'dailyCostBdt': dashboard.plan!.dailyCostBdt.toString(),
            if (dashboard.plan!.feedType != null)
              'feedType': dashboard.plan!.feedType!.apiValue,
            if (dashboard.plan!.unit != null)
              'unit': dashboard.plan!.unit!.apiValue,
            'notes': dashboard.plan!.notes,
            'createdAt': dashboard.plan!.createdAt.toIso8601String(),
            'updatedAt': dashboard.plan!.updatedAt.toIso8601String(),
          },
        'feedCost': {
          'totalCostBdt': dashboard.feedCost.totalCostBdt,
          'totalAmount': dashboard.feedCost.totalAmount,
          'todayCostBdt': dashboard.feedCost.todayCostBdt,
          'todayAmount': dashboard.feedCost.todayAmount,
          'avgDailyCostBdt': dashboard.feedCost.avgDailyCostBdt,
          'avgDailyAmount': dashboard.feedCost.avgDailyAmount,
        },
        'dailyFeed': {
          'plannedAmountKg': dashboard.dailyFeed.plannedAmountKg,
          'plannedCostBdt': dashboard.dailyFeed.plannedCostBdt,
          'todayAmountKg': dashboard.dailyFeed.todayAmountKg,
          'todayCostBdt': dashboard.dailyFeed.todayCostBdt,
          'mode': dashboard.dailyFeed.mode,
        },
        'daily': dashboard.daily
            .map(
              (d) => {'date': d.date, 'costBdt': d.costBdt, 'amount': d.amount},
            )
            .toList(),
      },
      LocalCacheContract.profileTtl,
    );
  }

  BatchFeedDashboard _parseFeedDashboard(Map<String, dynamic> data) {
    final dash = data['dashboard'] as Map<String, dynamic>? ?? data;
    return BatchFeedDashboard.fromJson(dash);
  }

  @override
  Future<ApiResult<BatchFeedDashboard>> getFeedDashboard(
    String batchId,
  ) async {
    try {
      final data = await getJson(
        _dio,
        FatteningApiPaths.feedDashboard(batchId),
      );
      final dashboard = _parseFeedDashboard(data);
      await _writeFeedDashboardCache(batchId, dashboard);
      return ApiResult.success(dashboard);
    } on AppException catch (e) {
      final cached = await readCachedFeedDashboard(batchId);
      if (cached != null) return ApiResult.success(cached);
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<BatchFeedPlan>> upsertFeedPlan(
    String batchId,
    BatchFeedPlan plan,
  ) async {
    try {
      final data = await putJson(
        _dio,
        FatteningApiPaths.feedPlan(batchId),
        plan.toUpsertJson(),
      );
      final raw = data['plan'];
      if (raw is! Map<String, dynamic>) {
        return const ApiResult.failure(
          AppException(message: 'Invalid feed plan response'),
        );
      }
      final saved = BatchFeedPlan.fromJson(raw);
      await getFeedDashboard(batchId);
      return ApiResult.success(saved);
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }

  @override
  Future<FatteningBatchRoi?> readCachedRoi(String batchId) async {
    final cached = await _cache.read(LocalCacheContract.fatteningRoiKey(batchId));
    if (cached == null) return null;
    return FatteningBatchRoi.fromJson({...cached, 'fromCache': true});
  }

  Future<void> _writeRoiCache(String batchId, FatteningBatchRoi roi) async {
    await _cache.write(
      LocalCacheContract.fatteningRoiKey(batchId),
      {
        'batchId': roi.batchId,
        'purchase': {
          'amountBdt': roi.purchase.amountBdt,
          if (roi.purchase.manualAmountBdt != null)
            'manualAmountBdt': roi.purchase.manualAmountBdt,
          if (roi.purchase.financeAmountBdt != null)
            'financeAmountBdt': roi.purchase.financeAmountBdt,
        },
        'feed': {
          'amountBdt': roi.feed.amountBdt,
          'recordCount': roi.feed.recordCount,
        },
        'treatment': {
          'amountBdt': roi.treatment.amountBdt,
          'recordCount': roi.treatment.recordCount,
        },
        'totalCostBdt': roi.totalCostBdt,
        'projectedSale': {'amountBdt': roi.projectedSaleBdt},
        'profitBdt': roi.profitBdt,
        if (roi.profitMarginPct != null)
          'profitMarginPct': roi.profitMarginPct,
        if (roi.settings != null)
          'settings': {
            if (roi.settings!.purchaseCostBdt != null)
              'purchaseCostBdt': roi.settings!.purchaseCostBdt,
            if (roi.settings!.projectedSaleBdt != null)
              'projectedSaleBdt': roi.settings!.projectedSaleBdt,
            'notes': roi.settings!.notes,
          },
      },
      LocalCacheContract.profileTtl,
    );
  }

  FatteningBatchRoi _parseRoi(Map<String, dynamic> data) {
    return FatteningBatchRoi.fromJson(data);
  }

  @override
  Future<ApiResult<FatteningBatchRoi>> getRoi(String batchId) async {
    try {
      final data = await getJson(_dio, FatteningApiPaths.roi(batchId));
      final roi = _parseRoi(data);
      await _writeRoiCache(batchId, roi);
      return ApiResult.success(roi);
    } on AppException catch (e) {
      final cached = await readCachedRoi(batchId);
      if (cached != null) return ApiResult.success(cached);
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<FatteningBatchRoi>> upsertRoi(
    String batchId,
    FatteningRoiSettings settings,
  ) async {
    try {
      final data = await putJson(
        _dio,
        FatteningApiPaths.roi(batchId),
        settings.toUpsertJson(),
      );
      final roi = _parseRoi(data);
      await _writeRoiCache(batchId, roi);
      return ApiResult.success(roi);
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }

  @override
  Future<QurbaniDashboard?> readCachedQurbani(String batchId) async {
    final cached = await _cache.read(
      LocalCacheContract.fatteningQurbaniKey(batchId),
    );
    if (cached == null) return null;
    return QurbaniDashboard.fromJson({...cached, 'fromCache': true});
  }

  @override
  Future<ApiResult<QurbaniDashboard>> getQurbaniDashboard(
    String batchId,
  ) async {
    try {
      final data = await getJson(_dio, FatteningApiPaths.qurbani(batchId));
      final dashboard = QurbaniDashboard.fromJson(data);
      await _cache.write(
        LocalCacheContract.fatteningQurbaniKey(batchId),
        {
          'batchId': dashboard.batchId,
          'goalType': dashboard.goalType.apiValue,
          'countdown': {
            'targetDate': dashboard.countdown.targetDate,
            'daysRemaining': dashboard.countdown.daysRemaining,
            'isPast': dashboard.countdown.isPast,
            'label': dashboard.countdown.label,
          },
          'readiness': {
            'scorePct': dashboard.readiness.scorePct,
            'status': dashboard.readiness.status.apiValue,
            'weightProgressPct': dashboard.readiness.weightProgressPct,
            'timeProgressPct': dashboard.readiness.timeProgressPct,
            'animalCount': dashboard.readiness.animalCount,
            'animalsWithWeights': dashboard.readiness.animalsWithWeights,
          },
          'animals': dashboard.animals
              .map(
                (a) => {
                  'animalId': a.animalId,
                  'animalName': a.animalName,
                  'initialWeightKg': a.initialWeightKg,
                  'currentWeightKg': a.currentWeightKg,
                  'gainKg': a.gainKg,
                  'targetWeightKg': a.targetWeightKg,
                  'progressPct': a.progressPct,
                  'recordCount': a.recordCount,
                },
              )
              .toList(),
        },
        LocalCacheContract.profileTtl,
      );
      return ApiResult.success(dashboard);
    } on AppException catch (e) {
      final cached = await readCachedQurbani(batchId);
      if (cached != null) return ApiResult.success(cached);
      return ApiResult.failure(e);
    }
  }
}

final fatteningRepositoryProvider = Provider<FatteningRepositoryContract>((
  ref,
) {
  return FatteningRepository(
    ref.watch(dioProvider),
    ref.watch(localCacheServiceProvider),
    ref.watch(outboxServiceProvider),
  );
});
