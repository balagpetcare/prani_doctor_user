import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/milk_dto.dart';
import '../data/milk_repository.dart';

class MilkListState {
  const MilkListState({
    this.records = const [],
    this.total = 0,
    this.page = 1,
    this.hasMore = false,
    this.pendingSyncCount = 0,
    this.fromCache = false,
    this.isRefreshing = false,
  });

  final List<MilkRecord> records;
  final int total;
  final int page;
  final bool hasMore;
  final int pendingSyncCount;
  final bool fromCache;
  final bool isRefreshing;

  MilkListState copyWith({
    List<MilkRecord>? records,
    int? total,
    int? page,
    bool? hasMore,
    int? pendingSyncCount,
    bool? fromCache,
    bool? isRefreshing,
  }) {
    return MilkListState(
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

final milkFromDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return _dateOnly(now.subtract(const Duration(days: 7)));
});

final milkToDateProvider = StateProvider<DateTime>(
  (ref) => _dateOnly(DateTime.now()),
);

final milkAnimalFilterProvider = StateProvider<String?>((ref) => null);
final milkSearchProvider = StateProvider<String>((ref) => '');
final milkSessionFilterProvider = StateProvider<MilkSessionFilter>(
  (ref) => MilkSessionFilter.all,
);

List<MilkRecord> _applyClientFilters(
  List<MilkRecord> records, {
  required String search,
  required MilkSessionFilter sessionFilter,
}) {
  var result = records;
  if (search.trim().isNotEmpty) {
    final q = search.trim().toLowerCase();
    result = result
        .where(
          (r) =>
              r.animalName.toLowerCase().contains(q) ||
              r.animalId.toLowerCase().contains(q) ||
              (r.notes ?? '').toLowerCase().contains(q),
        )
        .toList();
  }
  switch (sessionFilter) {
    case MilkSessionFilter.all:
      break;
    case MilkSessionFilter.morning:
      result = result.where((r) => r.session == MilkSession.morning).toList();
    case MilkSessionFilter.evening:
      result = result.where((r) => r.session == MilkSession.evening).toList();
  }
  return result;
}

final milkListProvider = AsyncNotifierProvider<MilkListNotifier, MilkListState>(
  MilkListNotifier.new,
);

class MilkListNotifier extends AsyncNotifier<MilkListState> {
  bool _loadInFlight = false;

  @override
  Future<MilkListState> build() async {
    final cached = await ref.read(milkRepositoryProvider).readCachedList();
    if (cached != null && cached.records.isNotEmpty) {
      unawaited(refresh(silent: true));
      return _fromPage(cached, page: 1);
    }
    return _load(page: 1);
  }

  MilkListState _fromPage(MilkPageResult pageResult, {required int page}) {
    final filtered = _applyClientFilters(
      pageResult.records,
      search: ref.read(milkSearchProvider),
      sessionFilter: ref.read(milkSessionFilterProvider),
    );
    return MilkListState(
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

  Future<MilkListState> _load({
    required int page,
    bool forceRefresh = false,
  }) async {
    final result = await ref
        .read(milkRepositoryProvider)
        .listRecords(
          from: ref.read(milkFromDateProvider),
          to: ref.read(milkToDateProvider),
          page: page,
          animalId: ref.read(milkAnimalFilterProvider),
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
    final previous = state.value ?? const MilkListState();
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

  void applyLocalFilters() async {
    final cached = await ref.read(milkRepositoryProvider).readCachedList();
    if (cached != null) {
      state = AsyncData(_fromPage(cached, page: 1));
      return;
    }
    final current = state.value;
    if (current == null) return;
    final filtered = _applyClientFilters(
      current.records,
      search: ref.read(milkSearchProvider),
      sessionFilter: ref.read(milkSessionFilterProvider),
    );
    state = AsyncData(
      current.copyWith(records: filtered, total: filtered.length),
    );
  }
}

final milkSummaryDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final milkTodaySummaryProvider = FutureProvider.autoDispose<MilkSummary>((
  ref,
) async {
  final today = _dateOnly(DateTime.now());
  final repo = ref.read(milkRepositoryProvider);
  final cached = await repo.readCachedSummary(today);
  if (cached != null) {
    return cached;
  }
  final result = await repo.getSummary(date: today);
  return result.when(success: (s) => s, failure: (e) => throw e);
});

final milkSummaryProvider = FutureProvider.autoDispose<MilkSummary>((
  ref,
) async {
  final date = ref.watch(milkSummaryDateProvider);
  final repo = ref.read(milkRepositoryProvider);
  final cached = await repo.readCachedSummary(date);
  if (cached != null) {
    return cached;
  }
  final result = await repo.getSummary(date: date);
  return result.when(success: (s) => s, failure: (e) => throw e);
});

final milkChartsProvider = FutureProvider.autoDispose<MilkChartsData>((
  ref,
) async {
  final repo = ref.read(milkRepositoryProvider);
  final cached = await repo.readCachedCharts();
  if (cached != null) {
    return cached;
  }
  final result = await repo.getCharts();
  return result.when(success: (c) => c, failure: (e) => throw e);
});

final milkRecordProvider = FutureProvider.autoDispose
    .family<MilkRecord, String>((ref, id) async {
      final result = await ref.read(milkRepositoryProvider).getRecord(id);
      return result.when(success: (r) => r, failure: (e) => throw e);
    });
