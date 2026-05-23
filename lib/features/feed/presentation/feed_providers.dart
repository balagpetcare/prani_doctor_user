import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/feed_dto.dart';
import '../data/feed_repository.dart';

class FeedListState {
  const FeedListState({
    this.records = const [],
    this.total = 0,
    this.page = 1,
    this.hasMore = false,
    this.pendingSyncCount = 0,
    this.fromCache = false,
    this.isRefreshing = false,
  });

  final List<FeedRecord> records;
  final int total;
  final int page;
  final bool hasMore;
  final int pendingSyncCount;
  final bool fromCache;
  final bool isRefreshing;

  FeedListState copyWith({
    List<FeedRecord>? records,
    int? total,
    int? page,
    bool? hasMore,
    int? pendingSyncCount,
    bool? fromCache,
    bool? isRefreshing,
  }) {
    return FeedListState(
      records: records ?? this.records,
      total: total ?? this.total,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      fromCache: fromCache ?? this.fromCache,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

final feedFromDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return _dateOnly(now.subtract(const Duration(days: 30)));
});

final feedToDateProvider = StateProvider<DateTime>(
  (ref) => _dateOnly(DateTime.now()),
);

final feedSearchProvider = StateProvider<String>((ref) => '');
final feedTypeFilterProvider = StateProvider<FeedType?>((ref) => null);
final feedAnimalFilterProvider = StateProvider<String?>((ref) => null);
final feedBatchFilterProvider = StateProvider<String?>((ref) => null);
final feedTargetFilterProvider = StateProvider<FeedTargetFilter>(
  (ref) => FeedTargetFilter.all,
);

List<FeedRecord> _applyTargetFilter(
  List<FeedRecord> records,
  FeedTargetFilter filter,
) {
  switch (filter) {
    case FeedTargetFilter.all:
      return records;
    case FeedTargetFilter.animal:
      return records
          .where((r) => r.animalId != null && r.animalId!.isNotEmpty)
          .toList();
    case FeedTargetFilter.group:
      return records
          .where((r) => r.batchId != null && r.batchId!.isNotEmpty)
          .toList();
  }
}

final feedListProvider = AsyncNotifierProvider<FeedListNotifier, FeedListState>(
  FeedListNotifier.new,
);

class FeedListNotifier extends AsyncNotifier<FeedListState> {
  bool _loadInFlight = false;

  @override
  Future<FeedListState> build() async {
    final cached = await ref.read(feedRepositoryProvider).readCachedList();
    if (cached != null && cached.records.isNotEmpty) {
      unawaited(refresh(silent: true));
      return _fromPage(cached, page: 1);
    }
    return _load(page: 1);
  }

  FeedListState _fromPage(FeedPageResult pageResult, {required int page}) {
    final filtered = _applyTargetFilter(
      pageResult.records,
      ref.read(feedTargetFilterProvider),
    );
    return FeedListState(
      records: page == 1
          ? filtered
          : [...state.value?.records ?? [], ...filtered],
      total: filtered.length,
      page: pageResult.page,
      hasMore: pageResult.hasMore,
      pendingSyncCount: pageResult.pendingSyncCount,
      fromCache: pageResult.fromCache,
    );
  }

  Future<FeedListState> _load({
    required int page,
    bool forceRefresh = false,
  }) async {
    final result = await ref
        .read(feedRepositoryProvider)
        .listRecords(
          from: ref.read(feedFromDateProvider),
          to: ref.read(feedToDateProvider),
          page: page,
          animalId: ref.read(feedAnimalFilterProvider),
          batchId: ref.read(feedBatchFilterProvider),
          search: ref.read(feedSearchProvider),
          feedType: ref.read(feedTypeFilterProvider),
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
    final previous = state.value ?? const FeedListState();
    if (!silent) {
      state = AsyncData(previous.copyWith(isRefreshing: true));
    }
    _loadInFlight = true;
    try {
      state = AsyncData(await _load(page: 1, forceRefresh: true));
    } catch (_) {
      if (previous.records.isNotEmpty) {
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

  void applyQuery() => reload(forceRefresh: true);

  Future<void> applyTargetFilter() async {
    final cached = await ref.read(feedRepositoryProvider).readCachedList();
    if (cached != null) {
      state = AsyncData(_fromPage(cached, page: 1));
      return;
    }
    final current = state.value;
    if (current == null) return;
    final filtered = _applyTargetFilter(
      current.records,
      ref.read(feedTargetFilterProvider),
    );
    state = AsyncData(
      current.copyWith(records: filtered, total: filtered.length),
    );
  }
}

final feedRecordProvider = FutureProvider.autoDispose
    .family<FeedRecord, String>((ref, id) async {
      final result = await ref.read(feedRepositoryProvider).getRecord(id);
      return result.when(success: (r) => r, failure: (e) => throw e);
    });

final feedCostSummaryProvider = FutureProvider.autoDispose<FeedCostData>((
  ref,
) async {
  final repo = ref.read(feedRepositoryProvider);
  final cached = await repo.readCachedCost();
  if (cached != null) {
    return cached;
  }
  final result = await repo.getCost();
  return result.when(success: (c) => c, failure: (e) => throw e);
});

final feedCostProvider = FutureProvider.autoDispose<FeedCostData>((ref) async {
  final repo = ref.read(feedRepositoryProvider);
  final from = ref.watch(feedFromDateProvider);
  final to = ref.watch(feedToDateProvider);
  final cached = await repo.readCachedCost();
  if (cached != null) {
    return cached;
  }
  final result = await repo.getCost(from: from, to: to);
  return result.when(success: (c) => c, failure: (e) => throw e);
});

final feedAnalyticsProvider = FutureProvider.autoDispose<FeedAnalyticsData>((
  ref,
) async {
  final repo = ref.read(feedRepositoryProvider);
  final from = ref.watch(feedFromDateProvider);
  final to = ref.watch(feedToDateProvider);
  final cached = await repo.readCachedAnalytics();
  if (cached != null) {
    return cached;
  }
  final result = await repo.getAnalytics(from: from, to: to);
  return result.when(success: (a) => a, failure: (e) => throw e);
});
