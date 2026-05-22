import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/milk_dto.dart';
import '../data/milk_repository.dart';

class MilkListState {
  const MilkListState({
    this.records = const [],
    this.total = 0,
    this.page = 1,
    this.hasMore = false,
    this.fromCache = false,
    this.isRefreshing = false,
  });

  final List<MilkRecord> records;
  final int total;
  final int page;
  final bool hasMore;
  final bool fromCache;
  final bool isRefreshing;

  MilkListState copyWith({
    List<MilkRecord>? records,
    int? total,
    int? page,
    bool? hasMore,
    bool? fromCache,
    bool? isRefreshing,
  }) {
    return MilkListState(
      records: records ?? this.records,
      total: total ?? this.total,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      fromCache: fromCache ?? this.fromCache,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

final milkAnimalFilterProvider = StateProvider<String?>((ref) => null);

final milkListProvider =
    AsyncNotifierProvider<MilkListNotifier, MilkListState>(MilkListNotifier.new);

class MilkListNotifier extends AsyncNotifier<MilkListState> {
  bool _loadInFlight = false;

  @override
  Future<MilkListState> build() async => _load(page: 1);

  Future<MilkListState> _load({required int page, bool forceRefresh = false}) async {
    final animalId = ref.read(milkAnimalFilterProvider);
    final result = await ref.read(milkRepositoryProvider).listRecords(
          page: page,
          animalId: animalId,
          forceRefresh: forceRefresh,
        );
    return result.when(
      success: (pageResult) => MilkListState(
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
    final previous = state.value ?? const MilkListState();
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
}

final milkSummaryDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final milkSummaryProvider = FutureProvider.autoDispose<MilkSummary>((ref) async {
  final date = ref.watch(milkSummaryDateProvider);
  final result = await ref.read(milkRepositoryProvider).getSummary(date: date);
  return result.when(success: (s) => s, failure: (e) => throw e);
});

final milkChartsProvider = FutureProvider.autoDispose<MilkChartsData>((ref) async {
  final result = await ref.read(milkRepositoryProvider).getCharts();
  return result.when(success: (c) => c, failure: (e) => throw e);
});

final milkRecordProvider =
    FutureProvider.autoDispose.family<MilkRecord, String>((ref, id) async {
  final result = await ref.read(milkRepositoryProvider).getRecord(id);
  return result.when(success: (r) => r, failure: (e) => throw e);
});
