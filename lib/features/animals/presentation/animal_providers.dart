import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/auto_refresh_guard.dart';
import '../../../core/providers/provider_stability.dart';
import '../../../core/session/session_providers.dart';
import '../../home/presentation/home_providers.dart';
import '../data/animal_dto.dart';
import '../data/animal_repository.dart';

class AnimalListState {
  const AnimalListState({
    this.animals = const [],
    this.total = 0,
    this.page = 1,
    this.hasMore = false,
    this.activeCount = 0,
    this.inactiveCount = 0,
    this.livestockCount = 0,
    this.fromCache = false,
    this.isRefreshing = false,
  });

  final List<AnimalProfile> animals;
  final int total;
  final int page;
  final bool hasMore;
  final int activeCount;
  final int inactiveCount;
  final int livestockCount;
  final bool fromCache;
  final bool isRefreshing;

  AnimalListState copyWith({
    List<AnimalProfile>? animals,
    int? total,
    int? page,
    bool? hasMore,
    int? activeCount,
    int? inactiveCount,
    int? livestockCount,
    bool? fromCache,
    bool? isRefreshing,
  }) {
    return AnimalListState(
      animals: animals ?? this.animals,
      total: total ?? this.total,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      activeCount: activeCount ?? this.activeCount,
      inactiveCount: inactiveCount ?? this.inactiveCount,
      livestockCount: livestockCount ?? this.livestockCount,
      fromCache: fromCache ?? this.fromCache,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

final animalSearchProvider = StateProvider<String>((ref) => '');
final animalFilterProvider = StateProvider<AnimalFilter>(
  (ref) => AnimalFilter.all,
);
final animalSortProvider = StateProvider<AnimalSort>(
  (ref) => AnimalSort.recentFirst,
);
final animalUploadProgressProvider = StateProvider<double?>((ref) => null);

final animalListProvider =
    AsyncNotifierProvider<AnimalListNotifier, AnimalListState>(
      AnimalListNotifier.new,
    );

class AnimalListNotifier extends AsyncNotifier<AnimalListState>
    with AsyncRefreshGuard<AnimalListState> {
  void _log(String message) {
    if (kDebugMode) debugPrint('[ANIMAL_LIST] $message');
  }

  @override
  Future<AnimalListState> build() async {
    ref.persistProvider('animalList');
    if (!ref.watch(protectedApisEnabledProvider)) {
      return const AnimalListState();
    }
    ref.watch(animalSearchProvider);
    ref.watch(animalFilterProvider);
    ref.watch(animalSortProvider);

    final cached = await ref.read(animalRepositoryProvider).readCachedList();
    if (cached != null && cached.animals.isNotEmpty) {
      ref.scheduleSilentRefresh(() => refresh(silent: true));
      return _fromPage(cached, page: 1);
    }
    return _load(page: 1);
  }

  AnimalListState _fromPage(AnimalPageResult pageResult, {required int page}) {
    return AnimalListState(
      animals: page == 1
          ? pageResult.animals
          : [...state.value?.animals ?? [], ...pageResult.animals],
      total: pageResult.total,
      page: pageResult.page,
      hasMore: pageResult.hasMore,
      activeCount: pageResult.activeCount,
      inactiveCount: pageResult.inactiveCount,
      livestockCount: pageResult.livestockCount,
      fromCache: pageResult.fromCache,
    );
  }

  /// Pure merge for optimistic list updates (testable).
  static AnimalListState applyUpsert(
    AnimalListState current,
    AnimalProfile animal,
  ) {
    final index = current.animals.indexWhere((item) => item.id == animal.id);
    final List<AnimalProfile> updated;
    if (index >= 0) {
      updated = [...current.animals];
      updated[index] = animal;
    } else {
      updated = [animal, ...current.animals];
    }
    var active = 0;
    var inactive = 0;
    var livestock = 0;
    for (final item in updated) {
      if (item.active) {
        active++;
      } else {
        inactive++;
      }
      if (item.category == 'LIVESTOCK') livestock++;
    }
    return current.copyWith(
      animals: updated,
      total: updated.length,
      activeCount: active,
      inactiveCount: inactive,
      livestockCount: livestock,
      fromCache: false,
    );
  }

  /// Optimistic insert/update after create/edit — does not touch profile state.
  void upsertLocal(AnimalProfile animal) {
    final current = state.value;
    if (current == null) return;
    _log('upsertLocal id=${animal.id}');
    state = AsyncData(applyUpsert(current, animal));
  }

  Future<AnimalListState> _load({
    required int page,
    bool forceRefresh = false,
  }) async {
    final result = await ref
        .read(animalRepositoryProvider)
        .listAnimals(
          page: page,
          search: ref.read(animalSearchProvider),
          filter: ref.read(animalFilterProvider),
          sort: ref.read(animalSortProvider),
          forceRefresh: forceRefresh,
        );
    return result.when(
      success: (pageResult) => _fromPage(pageResult, page: page),
      failure: (e) => throw e,
    );
  }

  Future<void> reload({bool forceRefresh = false}) async {
    if (!guardReload()) return;
    final previous = state.value ?? const AnimalListState();
    state = const AsyncLoading();
    try {
      state = AsyncData(await _load(page: 1, forceRefresh: forceRefresh));
      _log('reload ok count=${state.value?.animals.length ?? 0}');
    } catch (e, st) {
      if (previous.animals.isNotEmpty) {
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
    final previous = state.value ?? const AnimalListState();
    if (!silent) {
      state = AsyncData(previous.copyWith(isRefreshing: true));
    }
    try {
      state = AsyncData(await _load(page: 1, forceRefresh: true));
      _log('refresh ok count=${state.value?.animals.length ?? 0}');
    } catch (_) {
      state = AsyncData(previous.copyWith(isRefreshing: false));
    } finally {
      endRefresh();
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || anyRefreshInFlight) return;
    refreshInFlight = true;
    try {
      state = AsyncData(await _load(page: current.page + 1));
    } finally {
      refreshInFlight = false;
    }
  }

  void applyQuery() => reload(forceRefresh: true);

  Future<void> deactivate(String id) async {
    final result = await ref
        .read(animalRepositoryProvider)
        .deactivateAnimal(id);
    result.when(
      success: (_) {
        ref.invalidate(animalDetailProvider(id));
        ref.invalidate(dashboardProvider);
        invalidateDashboardSections(ref);
        reload(forceRefresh: true);
      },
      failure: (e) => throw e,
    );
  }
}

final animalDetailProvider = FutureProvider.autoDispose
    .family<AnimalDetail, String>((ref, id) async {
      final result = await ref.read(animalRepositoryProvider).getAnimal(id);
      return result.when(success: (detail) => detail, failure: (e) => throw e);
    });
