import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/fattening_batch_dto.dart';
import '../data/fattening_repository.dart';
import '../data/fattening_feed_dto.dart';
import '../data/fattening_qurbani_dto.dart';
import '../data/fattening_roi_dto.dart';
import '../weight/data/weight_dto.dart';

class FatteningListState {
  const FatteningListState({
    this.batches = const [],
    this.total = 0,
    this.page = 1,
    this.hasMore = false,
    this.pendingSyncCount = 0,
    this.fromCache = false,
    this.isRefreshing = false,
  });

  final List<FatteningBatch> batches;
  final int total;
  final int page;
  final bool hasMore;
  final int pendingSyncCount;
  final bool fromCache;
  final bool isRefreshing;

  FatteningListState copyWith({
    List<FatteningBatch>? batches,
    int? total,
    int? page,
    bool? hasMore,
    int? pendingSyncCount,
    bool? fromCache,
    bool? isRefreshing,
  }) {
    return FatteningListState(
      batches: batches ?? this.batches,
      total: total ?? this.total,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      fromCache: fromCache ?? this.fromCache,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

final fatteningListRefreshProvider = StateProvider<int>((ref) => 0);

final fatteningStatusFilterProvider = StateProvider<FatteningBatchStatus?>(
  (ref) => null,
);

final fatteningBatchListProvider = AsyncNotifierProvider.family<
  FatteningBatchListNotifier,
  FatteningListState,
  String
>(FatteningBatchListNotifier.new);

class FatteningBatchListNotifier extends FamilyAsyncNotifier<
  FatteningListState,
  String
> {
  @override
  Future<FatteningListState> build(String farmId) async {
    ref.watch(fatteningListRefreshProvider);
    final status = ref.watch(fatteningStatusFilterProvider);
    final repo = ref.read(fatteningRepositoryProvider);
    final cached = await repo.readCachedList(farmId);
    if (cached != null && cached.batches.isNotEmpty) {
      unawaited(refresh(silent: true));
      return _fromPage(_filterCachedPage(cached, status));
    }
    return _load(farmId, forceRefresh: false);
  }

  FatteningBatchPageResult _filterCachedPage(
    FatteningBatchPageResult page,
    FatteningBatchStatus? status,
  ) {
    if (status == null) return page;
    final batches = page.batches.where((b) => b.status == status).toList();
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

  FatteningListState _fromPage(FatteningBatchPageResult page) {
    return FatteningListState(
      batches: page.batches,
      total: page.total,
      page: page.page,
      hasMore: page.hasMore,
      pendingSyncCount: page.pendingSyncCount,
      fromCache: page.fromCache,
    );
  }

  Future<FatteningListState> _load(
    String farmId, {
    bool forceRefresh = false,
  }) async {
    final status = ref.read(fatteningStatusFilterProvider);
    final result = await ref
        .read(fatteningRepositoryProvider)
        .listBatches(farmId: farmId, status: status, forceRefresh: forceRefresh);
    return result.when(
      success: _fromPage,
      failure: (e) => throw e,
    );
  }

  Future<void> refresh({bool silent = false}) async {
    final farmId = arg; // family parameter
    if (!silent) {
      state = AsyncData(
        (state.value ?? const FatteningListState()).copyWith(
          isRefreshing: true,
        ),
      );
    }
    try {
      final next = await _load(farmId, forceRefresh: true);
      state = AsyncData(next.copyWith(isRefreshing: false));
    } catch (e, st) {
      if (!silent) state = AsyncError(e, st);
    }
  }

  void applyFilter() {
    ref.invalidateSelf();
  }
}

final fatteningBatchDetailProvider = FutureProvider.autoDispose.family<
  FatteningBatchDetail,
  String
>((ref, batchId) async {
  ref.watch(fatteningListRefreshProvider);
  final repo = ref.read(fatteningRepositoryProvider);
  final cached = await repo.readCachedDetail(batchId);
  if (cached != null) {
    unawaited(repo.getBatch(batchId, forceRefresh: true));
    return cached;
  }
  final result = await repo.getBatch(batchId, forceRefresh: true);
  return result.when(
    success: (detail) => detail,
    failure: (e) => throw e,
  );
});

void refreshFatteningAfterMutation(
  WidgetRef ref, {
  String? farmId,
  String? batchId,
}) {
  ref.read(fatteningListRefreshProvider.notifier).state++;
  if (farmId != null) {
    ref.invalidate(fatteningBatchListProvider(farmId));
  }
  if (batchId != null) {
    ref.invalidate(fatteningWeightHistoryProvider(batchId));
    ref.invalidate(fatteningBatchProgressProvider(batchId));
    ref.invalidate(fatteningBatchDetailProvider(batchId));
    ref.invalidate(fatteningQurbaniProvider(batchId));
  }
}

final fatteningFeedDashboardProvider = FutureProvider.autoDispose.family<
  BatchFeedDashboard,
  String
>((ref, batchId) async {
  ref.watch(fatteningListRefreshProvider);
  final result = await ref
      .read(fatteningRepositoryProvider)
      .getFeedDashboard(batchId);
  return result.when(
    success: (data) => data,
    failure: (e) => throw e,
  );
});

final fatteningBatchRoiProvider = FutureProvider.autoDispose.family<
  FatteningBatchRoi,
  String
>((ref, batchId) async {
  ref.watch(fatteningListRefreshProvider);
  final result = await ref.read(fatteningRepositoryProvider).getRoi(batchId);
  return result.when(
    success: (data) => data,
    failure: (e) => throw e,
  );
});

final fatteningQurbaniProvider = FutureProvider.autoDispose.family<
  QurbaniDashboard,
  String
>((ref, batchId) async {
  ref.watch(fatteningListRefreshProvider);
  final result = await ref
      .read(fatteningRepositoryProvider)
      .getQurbaniDashboard(batchId);
  return result.when(
    success: (data) => data,
    failure: (e) => throw e,
  );
});

final fatteningWeightHistoryProvider = FutureProvider.autoDispose.family<
  WeightHistoryResult,
  String
>((ref, batchId) async {
  ref.watch(fatteningListRefreshProvider);
  final result = await ref
      .read(fatteningRepositoryProvider)
      .getWeightHistory(batchId: batchId, forceRefresh: true);
  return result.when(
    success: (data) => data,
    failure: (e) => throw e,
  );
});

final fatteningBatchProgressProvider = FutureProvider.autoDispose.family<
  BatchWeightProgress,
  String
>((ref, batchId) async {
  ref.watch(fatteningListRefreshProvider);
  final result =
      await ref.read(fatteningRepositoryProvider).getBatchProgress(batchId);
  return result.when(
    success: (data) => data,
    failure: (e) => throw e,
  );
});
