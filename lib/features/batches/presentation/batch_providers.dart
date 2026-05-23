import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/presentation/home_providers.dart';
import '../data/batch_dto.dart';
import '../data/batch_repository.dart';

class BatchListState {
  const BatchListState({
    this.batches = const [],
    this.total = 0,
    this.page = 1,
    this.hasMore = false,
    this.withAnimalsCount = 0,
    this.emptyCount = 0,
    this.pendingSyncCount = 0,
    this.fromCache = false,
    this.isRefreshing = false,
  });

  final List<AnimalBatch> batches;
  final int total;
  final int page;
  final bool hasMore;
  final int withAnimalsCount;
  final int emptyCount;
  final int pendingSyncCount;
  final bool fromCache;
  final bool isRefreshing;

  BatchListState copyWith({
    List<AnimalBatch>? batches,
    int? total,
    int? page,
    bool? hasMore,
    int? withAnimalsCount,
    int? emptyCount,
    int? pendingSyncCount,
    bool? fromCache,
    bool? isRefreshing,
  }) {
    return BatchListState(
      batches: batches ?? this.batches,
      total: total ?? this.total,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      withAnimalsCount: withAnimalsCount ?? this.withAnimalsCount,
      emptyCount: emptyCount ?? this.emptyCount,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      fromCache: fromCache ?? this.fromCache,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

final batchSearchProvider = StateProvider<String>((ref) => '');
final batchFilterProvider = StateProvider<BatchFilter>(
  (ref) => BatchFilter.all,
);
final batchSortProvider = StateProvider<BatchSort>(
  (ref) => BatchSort.recentFirst,
);

final batchListProvider =
    AsyncNotifierProvider<BatchListNotifier, BatchListState>(
      BatchListNotifier.new,
    );

class BatchListNotifier extends AsyncNotifier<BatchListState> {
  bool _loadInFlight = false;

  @override
  Future<BatchListState> build() async {
    final cached = await ref.read(batchRepositoryProvider).readCachedList();
    if (cached != null && cached.batches.isNotEmpty) {
      unawaited(refresh(silent: true));
      return _fromPage(cached, page: 1);
    }
    return _load(page: 1);
  }

  BatchListState _fromPage(BatchPageResult pageResult, {required int page}) {
    return BatchListState(
      batches: page == 1
          ? pageResult.batches
          : [...state.value?.batches ?? [], ...pageResult.batches],
      total: pageResult.total,
      page: pageResult.page,
      hasMore: pageResult.hasMore,
      withAnimalsCount: pageResult.withAnimalsCount,
      emptyCount: pageResult.emptyCount,
      pendingSyncCount: pageResult.pendingSyncCount,
      fromCache: pageResult.fromCache,
    );
  }

  Future<BatchListState> _load({
    required int page,
    bool forceRefresh = false,
  }) async {
    final result = await ref
        .read(batchRepositoryProvider)
        .listBatches(
          page: page,
          search: ref.read(batchSearchProvider),
          filter: ref.read(batchFilterProvider),
          sort: ref.read(batchSortProvider),
          forceRefresh: forceRefresh,
        );
    return result.when(
      success: (pageResult) => _fromPage(pageResult, page: page),
      failure: (e) => throw e,
    );
  }

  Future<void> reload({bool forceRefresh = false}) async {
    if (_loadInFlight) return;
    _loadInFlight = true;
    state = const AsyncLoading();
    try {
      state = AsyncData(await _load(page: 1, forceRefresh: forceRefresh));
    } catch (e, st) {
      state = AsyncError(e, st);
    } finally {
      _loadInFlight = false;
    }
  }

  Future<void> refresh({bool silent = false}) async {
    if (_loadInFlight) return;
    final previous = state.value ?? const BatchListState();
    if (!silent) {
      state = AsyncData(previous.copyWith(isRefreshing: true));
    }
    _loadInFlight = true;
    try {
      state = AsyncData(await _load(page: 1, forceRefresh: true));
    } catch (_) {
      if (previous.batches.isNotEmpty) {
        state = AsyncData(previous);
      }
    } finally {
      _loadInFlight = false;
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || _loadInFlight) return;
    _loadInFlight = true;
    try {
      state = AsyncData(await _load(page: current.page + 1));
    } finally {
      _loadInFlight = false;
    }
  }

  Future<void> deleteBatch(String id) async {
    final result = await ref.read(batchRepositoryProvider).deleteBatch(id);
    result.when(
      success: (_) {
        ref.invalidate(batchListProvider);
        ref.invalidate(batchOptionsProvider);
        ref.invalidate(dashboardProvider);
        ref.invalidate(dashboardMetricsProvider);
      },
      failure: (e) => throw e,
    );
  }

  void applyQuery() => reload(forceRefresh: true);
}

final batchDetailProvider = FutureProvider.autoDispose
    .family<BatchDetail, String>((ref, id) async {
      final result = await ref.read(batchRepositoryProvider).getBatch(id);
      return result.when(success: (detail) => detail, failure: (e) => throw e);
    });

final batchOptionsProvider = FutureProvider.autoDispose<List<AnimalBatch>>((
  ref,
) async {
  final result = await ref
      .read(batchRepositoryProvider)
      .listBatches(pageSize: 200);
  return result.when(success: (page) => page.batches, failure: (_) => []);
});
