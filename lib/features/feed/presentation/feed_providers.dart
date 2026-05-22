import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/feed_dto.dart';
import '../data/feed_repository.dart';

class FeedListState {
  const FeedListState({
    this.records = const [],
    this.total = 0,
    this.page = 1,
    this.hasMore = false,
    this.fromCache = false,
    this.isRefreshing = false,
  });

  final List<FeedRecord> records;
  final int total;
  final int page;
  final bool hasMore;
  final bool fromCache;
  final bool isRefreshing;

  FeedListState copyWith({
    List<FeedRecord>? records,
    int? total,
    int? page,
    bool? hasMore,
    bool? fromCache,
    bool? isRefreshing,
  }) {
    return FeedListState(
      records: records ?? this.records,
      total: total ?? this.total,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      fromCache: fromCache ?? this.fromCache,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

final feedSearchProvider = StateProvider<String>((ref) => '');
final feedTypeFilterProvider = StateProvider<FeedType?>((ref) => null);

final feedListProvider =
    AsyncNotifierProvider<FeedListNotifier, FeedListState>(FeedListNotifier.new);

class FeedListNotifier extends AsyncNotifier<FeedListState> {
  bool _loadInFlight = false;

  @override
  Future<FeedListState> build() async => _load(page: 1);

  Future<FeedListState> _load({required int page, bool forceRefresh = false}) async {
    final result = await ref.read(feedRepositoryProvider).listRecords(
          page: page,
          search: ref.read(feedSearchProvider),
          feedType: ref.read(feedTypeFilterProvider),
          forceRefresh: forceRefresh,
        );
    return result.when(
      success: (pageResult) => FeedListState(
        records: page == 1
            ? pageResult.records
            : [...state.value?.records ?? [], ...pageResult.records],
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
    final previous = state.value ?? const FeedListState();
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

final feedRecordProvider =
    FutureProvider.autoDispose.family<FeedRecord, String>((ref, id) async {
  final result = await ref.read(feedRepositoryProvider).getRecord(id);
  return result.when(success: (r) => r, failure: (e) => throw e);
});

final feedCostProvider = FutureProvider.autoDispose<FeedCostData>((ref) async {
  final result = await ref.read(feedRepositoryProvider).getCost();
  return result.when(success: (c) => c, failure: (e) => throw e);
});

final feedAnalyticsProvider = FutureProvider.autoDispose<FeedAnalyticsData>((ref) async {
  final result = await ref.read(feedRepositoryProvider).getAnalytics();
  return result.when(success: (a) => a, failure: (e) => throw e);
});
