import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/auto_refresh_guard.dart';
import '../../../core/providers/provider_stability.dart';
import '../../../core/session/session_providers.dart';
import '../../ecosystem/presentation/active_farm_ref_provider.dart';
import '../data/livestock_dto.dart';
import '../data/livestock_repository.dart';

class LivestockListState {
  const LivestockListState({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.hasMore = false,
    this.fromCache = false,
    this.isRefreshing = false,
  });

  final List<LivestockProfile> items;
  final int total;
  final int page;
  final bool hasMore;
  final bool fromCache;
  final bool isRefreshing;

  LivestockListState copyWith({
    List<LivestockProfile>? items,
    int? total,
    int? page,
    bool? hasMore,
    bool? fromCache,
    bool? isRefreshing,
  }) {
    return LivestockListState(
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      fromCache: fromCache ?? this.fromCache,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

final livestockSearchProvider = StateProvider<String>((ref) => '');
final livestockFilterProvider = StateProvider<LivestockFilter>(
  (ref) => LivestockFilter.all,
);
final livestockSortProvider = StateProvider<LivestockSort>(
  (ref) => LivestockSort.recentFirst,
);

final livestockListProvider =
    AsyncNotifierProvider<LivestockListNotifier, LivestockListState>(
      LivestockListNotifier.new,
    );

class LivestockListNotifier extends AsyncNotifier<LivestockListState>
    with AsyncRefreshGuard<LivestockListState> {
  @override
  Future<LivestockListState> build() async {
    ref.persistProvider('livestockList');
    if (!ref.watch(protectedApisEnabledProvider)) {
      return const LivestockListState();
    }
    final farmRef = ref.watch(activeFarmRefProvider);
    if (farmRef == null || farmRef.isEmpty) {
      return const LivestockListState();
    }
    ref.watch(livestockSearchProvider);
    ref.watch(livestockFilterProvider);
    ref.watch(livestockSortProvider);

    final cached = await ref
        .read(livestockRepositoryProvider)
        .readCachedList(farmRef);
    if (cached != null && cached.items.isNotEmpty) {
      ref.scheduleSilentRefresh(() => refresh(silent: true));
      return _fromPage(cached, page: 1);
    }
    return _load(farmRef: farmRef, page: 1);
  }

  LivestockListState _fromPage(LivestockPageResult pageResult, {required int page}) {
    final current = state.value;
    return LivestockListState(
      items: page == 1
          ? pageResult.items
          : [...current?.items ?? [], ...pageResult.items],
      total: pageResult.total,
      page: pageResult.page,
      hasMore: pageResult.hasMore,
      fromCache: pageResult.fromCache,
    );
  }

  Future<LivestockListState> _load({
    required String farmRef,
    required int page,
    bool forceRefresh = false,
  }) async {
    final result = await ref
        .read(livestockRepositoryProvider)
        .listLivestock(
          farmRef: farmRef,
          page: page,
          search: ref.read(livestockSearchProvider),
          filter: ref.read(livestockFilterProvider),
          sort: ref.read(livestockSortProvider),
          forceRefresh: forceRefresh,
        );
    return result.when(
      success: (pageResult) => _fromPage(pageResult, page: page),
      failure: (e) => throw e,
    );
  }

  Future<void> reload({bool forceRefresh = false}) async {
    if (!guardReload()) return;
    final farmRef = ref.read(activeFarmRefProvider);
    if (farmRef == null || farmRef.isEmpty) return;
    final previous = state.value ?? const LivestockListState();
    state = const AsyncLoading();
    try {
      state = AsyncData(await _load(farmRef: farmRef, page: 1, forceRefresh: forceRefresh));
    } catch (e, st) {
      if (previous.items.isNotEmpty) {
        state = AsyncData(previous.copyWith(isRefreshing: false));
      } else {
        state = AsyncError(e, st);
      }
    } finally {
      endReload();
    }
  }

  Future<void> refresh({bool silent = false}) async {
    if (!guardRefresh(silent: silent)) return;
    final farmRef = ref.read(activeFarmRefProvider);
    if (farmRef == null || farmRef.isEmpty) return;
    final previous = state.value ?? const LivestockListState();
    if (!silent) {
      state = AsyncData(previous.copyWith(isRefreshing: true));
    }
    try {
      state = AsyncData(
        await _load(farmRef: farmRef, page: 1, forceRefresh: true),
      );
    } catch (_) {
      state = AsyncData(previous.copyWith(isRefreshing: false));
    } finally {
      endRefresh();
    }
  }

  Future<void> loadMore() async {
    final farmRef = ref.read(activeFarmRefProvider);
    final current = state.value;
    if (farmRef == null ||
        farmRef.isEmpty ||
        current == null ||
        !current.hasMore ||
        anyRefreshInFlight) {
      return;
    }
    refreshInFlight = true;
    try {
      state = AsyncData(await _load(farmRef: farmRef, page: current.page + 1));
    } finally {
      refreshInFlight = false;
    }
  }

  void applyQuery() => reload(forceRefresh: true);
}

final livestockDetailProvider = FutureProvider.autoDispose
    .family<LivestockProfile, String>((ref, id) async {
      final result = await ref
          .read(livestockRepositoryProvider)
          .getLivestock(id);
      return result.when(success: (profile) => profile, failure: (e) => throw e);
    });

final livestockTimelineProvider = FutureProvider.autoDispose
    .family<List<LivestockTimelineItem>, String>((ref, id) async {
      final result = await ref.read(livestockRepositoryProvider).loadTimeline(id);
      return result.when(success: (items) => items, failure: (e) => throw e);
    });
