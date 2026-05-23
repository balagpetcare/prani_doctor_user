import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/health_dto.dart';
import '../data/health_repository.dart';

class HealthListState {
  const HealthListState({
    this.records = const [],
    this.total = 0,
    this.page = 1,
    this.hasMore = false,
    this.pendingSyncCount = 0,
    this.fromCache = false,
    this.isRefreshing = false,
  });

  final List<HealthEvent> records;
  final int total;
  final int page;
  final bool hasMore;
  final int pendingSyncCount;
  final bool fromCache;
  final bool isRefreshing;

  HealthListState copyWith({
    List<HealthEvent>? records,
    int? total,
    int? page,
    bool? hasMore,
    int? pendingSyncCount,
    bool? fromCache,
    bool? isRefreshing,
  }) {
    return HealthListState(
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

class HealthTimelineState {
  const HealthTimelineState({
    this.groups = const [],
    this.total = 0,
    this.page = 1,
    this.hasMore = false,
    this.fromCache = false,
    this.isRefreshing = false,
  });

  final List<HealthTimelineGroup> groups;
  final int total;
  final int page;
  final bool hasMore;
  final bool fromCache;
  final bool isRefreshing;

  HealthTimelineState copyWith({
    List<HealthTimelineGroup>? groups,
    int? total,
    int? page,
    bool? hasMore,
    bool? fromCache,
    bool? isRefreshing,
  }) {
    return HealthTimelineState(
      groups: groups ?? this.groups,
      total: total ?? this.total,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      fromCache: fromCache ?? this.fromCache,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

final healthFromDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return _dateOnly(now.subtract(const Duration(days: 90)));
});

final healthToDateProvider = StateProvider<DateTime>(
  (ref) => _dateOnly(DateTime.now()),
);

final healthSearchProvider = StateProvider<String>((ref) => '');
final healthEventTypeFilterProvider = StateProvider<HealthEventType?>(
  (ref) => null,
);
final healthAnimalFilterProvider = StateProvider<String?>((ref) => null);

HealthListState _fromPage(
  HealthPageResult page, {
  required int pageNum,
  HealthListState? previous,
}) {
  return HealthListState(
    records: pageNum == 1
        ? page.records
        : [...previous?.records ?? [], ...page.records],
    total: page.total,
    page: page.page,
    hasMore: page.hasMore,
    pendingSyncCount: page.pendingSyncCount,
    fromCache: page.fromCache,
  );
}

HealthTimelineState _fromTimeline(
  HealthTimelineResult timeline, {
  required int pageNum,
  HealthTimelineState? previous,
}) {
  return HealthTimelineState(
    groups: pageNum == 1
        ? timeline.groups
        : [...previous?.groups ?? [], ...timeline.groups],
    total: timeline.total,
    page: timeline.page,
    hasMore: timeline.hasMore,
    fromCache: timeline.fromCache,
  );
}

final healthProvider =
    AsyncNotifierProvider<HealthListNotifier, HealthListState>(
      HealthListNotifier.new,
    );

class HealthListNotifier extends AsyncNotifier<HealthListState> {
  bool _loadInFlight = false;

  @override
  Future<HealthListState> build() async {
    final cached = await ref.read(healthRepositoryProvider).readCachedList();
    if (cached != null && cached.records.isNotEmpty) {
      unawaited(refresh(silent: true));
      return _fromPage(cached, pageNum: 1);
    }
    return _load(page: 1);
  }

  Future<HealthListState> _load({
    required int page,
    bool forceRefresh = false,
  }) async {
    final result = await ref
        .read(healthRepositoryProvider)
        .listRecords(
          from: ref.read(healthFromDateProvider),
          to: ref.read(healthToDateProvider),
          animalId: ref.read(healthAnimalFilterProvider),
          eventType: ref.read(healthEventTypeFilterProvider),
          search: ref.read(healthSearchProvider),
          page: page,
          limit: 20,
          forceRefresh: forceRefresh,
        );
    return result.when(
      success: (pageResult) =>
          _fromPage(pageResult, pageNum: page, previous: state.value),
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
    final previous = state.value ?? const HealthListState();
    if (!silent) state = AsyncData(previous.copyWith(isRefreshing: true));
    _loadInFlight = true;
    try {
      state = AsyncData(await _load(page: 1, forceRefresh: true));
    } catch (_) {
      if (previous.records.isNotEmpty) state = AsyncData(previous);
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
}

final healthTimelineProvider =
    AsyncNotifierProvider<HealthTimelineNotifier, HealthTimelineState>(
      HealthTimelineNotifier.new,
    );

class HealthTimelineNotifier extends AsyncNotifier<HealthTimelineState> {
  bool _loadInFlight = false;

  @override
  Future<HealthTimelineState> build() async {
    final cached = await ref
        .read(healthRepositoryProvider)
        .readCachedTimeline();
    if (cached != null && cached.groups.isNotEmpty) {
      unawaited(refresh(silent: true));
      return _fromTimeline(cached, pageNum: 1);
    }
    return _load(page: 1);
  }

  Future<HealthTimelineState> _load({
    required int page,
    bool forceRefresh = false,
  }) async {
    final result = await ref
        .read(healthRepositoryProvider)
        .getTimeline(
          from: ref.read(healthFromDateProvider),
          to: ref.read(healthToDateProvider),
          animalId: ref.read(healthAnimalFilterProvider),
          eventType: ref.read(healthEventTypeFilterProvider),
          search: ref.read(healthSearchProvider),
          page: page,
          limit: 20,
          forceRefresh: forceRefresh,
        );
    return result.when(
      success: (timeline) =>
          _fromTimeline(timeline, pageNum: page, previous: state.value),
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
    final previous = state.value ?? const HealthTimelineState();
    if (!silent) state = AsyncData(previous.copyWith(isRefreshing: true));
    _loadInFlight = true;
    try {
      state = AsyncData(await _load(page: 1, forceRefresh: true));
    } catch (_) {
      if (previous.groups.isNotEmpty) state = AsyncData(previous);
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
}

final healthRecordProvider = FutureProvider.autoDispose
    .family<HealthEvent, String>((ref, id) async {
      final result = await ref.read(healthRepositoryProvider).getRecord(id);
      return result.when(success: (r) => r, failure: (e) => throw e);
    });

final healthSummaryProvider = FutureProvider.autoDispose<HealthSummaryData>((
  ref,
) async {
  final repo = ref.read(healthRepositoryProvider);
  ref.watch(healthFromDateProvider);
  ref.watch(healthToDateProvider);
  ref.watch(healthAnimalFilterProvider);

  final cached = await repo.readCachedList();
  if (cached != null && cached.records.isNotEmpty) {
    return HealthSummaryData.fromRecords(
      cached.records,
      total: cached.total,
      fromCache: true,
    );
  }

  final result = await repo.listRecords(
    from: ref.read(healthFromDateProvider),
    to: ref.read(healthToDateProvider),
    animalId: ref.read(healthAnimalFilterProvider),
    page: 1,
    limit: 100,
    search: '',
    forceRefresh: false,
  );
  return result.when(
    success: (page) =>
        HealthSummaryData.fromRecords(page.records, total: page.total),
    failure: (e) => throw e,
  );
});

final healthAnalyticsProvider = FutureProvider.autoDispose<HealthAnalyticsData>(
  (ref) async {
    final repo = ref.read(healthRepositoryProvider);
    ref.watch(healthFromDateProvider);
    ref.watch(healthToDateProvider);
    ref.watch(healthAnimalFilterProvider);
    ref.watch(healthEventTypeFilterProvider);

    final cached = await repo.readCachedList();
    if (cached != null && cached.records.isNotEmpty) {
      return HealthAnalyticsData.fromRecords(cached.records, fromCache: true);
    }

    final result = await repo.listRecords(
      from: ref.read(healthFromDateProvider),
      to: ref.read(healthToDateProvider),
      animalId: ref.read(healthAnimalFilterProvider),
      eventType: ref.read(healthEventTypeFilterProvider),
      page: 1,
      limit: 100,
      search: '',
      forceRefresh: false,
    );
    return result.when(
      success: (page) => HealthAnalyticsData.fromRecords(page.records),
      failure: (e) => throw e,
    );
  },
);

final healthRecentEventsProvider =
    FutureProvider.autoDispose<List<HealthEvent>>((ref) async {
      final cached = await ref.read(healthRepositoryProvider).readCachedList();
      if (cached != null && cached.records.isNotEmpty) {
        final sorted = [...cached.records]
          ..sort((a, b) => b.recordedDate.compareTo(a.recordedDate));
        return sorted.take(5).toList();
      }
      final result = await ref
          .read(healthRepositoryProvider)
          .listRecords(page: 1, limit: 5, search: '', forceRefresh: false);
      return result.when(
        success: (page) => page.records,
        failure: (e) => throw e,
      );
    });
