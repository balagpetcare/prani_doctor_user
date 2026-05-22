import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/batch_dto.dart';
import '../data/batch_repository.dart';

class BatchListState {
  const BatchListState({
    this.batches = const [],
    this.total = 0,
    this.page = 1,
    this.hasMore = false,
    this.fromCache = false,
    this.isRefreshing = false,
  });

  final List<AnimalBatch> batches;
  final int total;
  final int page;
  final bool hasMore;
  final bool fromCache;
  final bool isRefreshing;

  BatchListState copyWith({
    List<AnimalBatch>? batches,
    int? total,
    int? page,
    bool? hasMore,
    bool? fromCache,
    bool? isRefreshing,
  }) {
    return BatchListState(
      batches: batches ?? this.batches,
      total: total ?? this.total,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      fromCache: fromCache ?? this.fromCache,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

final batchSearchProvider = StateProvider<String>((ref) => '');
final batchFilterProvider = StateProvider<BatchFilter>((ref) => BatchFilter.all);

final batchListProvider =
    AsyncNotifierProvider<BatchListNotifier, BatchListState>(BatchListNotifier.new);

class BatchListNotifier extends AsyncNotifier<BatchListState> {
  bool _loadInFlight = false;

  @override
  Future<BatchListState> build() async => _load(page: 1);

  Future<BatchListState> _load({required int page, bool forceRefresh = false}) async {
    final result = await ref.read(batchRepositoryProvider).listBatches(
          page: page,
          search: ref.read(batchSearchProvider),
          filter: ref.read(batchFilterProvider),
          forceRefresh: forceRefresh,
        );
    return result.when(
      success: (pageResult) => BatchListState(
        batches: page == 1
            ? pageResult.batches
            : [...state.value?.batches ?? [], ...pageResult.batches],
        total: pageResult.total,
        page: pageResult.page,
        hasMore: pageResult.hasMore,
        fromCache: pageResult.fromCache,
      ),
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

  Future<void> refresh() async {
    if (_loadInFlight) return;
    final previous = state.value ?? const BatchListState();
    state = AsyncData(previous.copyWith(isRefreshing: true));
    try {
      state = AsyncData(await _load(page: 1, forceRefresh: true));
    } catch (_) {
      state = AsyncData(previous);
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

  void applyQuery() => reload(forceRefresh: true);
}

final batchDetailProvider =
    FutureProvider.autoDispose.family<BatchDetail, String>((ref, id) async {
  final result = await ref.read(batchRepositoryProvider).getBatch(id);
  return result.when(
    success: (detail) => detail,
    failure: (e) => throw e,
  );
});

final batchOptionsProvider = FutureProvider.autoDispose<List<AnimalBatch>>((ref) async {
  final result = await ref.read(batchRepositoryProvider).listBatches(pageSize: 200);
  return result.when(
    success: (page) => page.batches,
    failure: (_) => [],
  );
});
