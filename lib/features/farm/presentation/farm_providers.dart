import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/presentation/home_providers.dart';
import '../../profile/presentation/profile_providers.dart';
import '../data/farm_dto.dart';
import '../data/farm_location.dart';
import '../data/farm_repository.dart';

class FarmListState {
  const FarmListState({
    this.farms = const [],
    this.total = 0,
    this.page = 1,
    this.pageSize = 20,
    this.hasMore = false,
    this.search = '',
    this.filter = FarmFilter.all,
    this.sort = FarmSort.nameAsc,
    this.fromCache = false,
    this.isRefreshing = false,
  });

  final List<Farm> farms;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;
  final String search;
  final FarmFilter filter;
  final FarmSort sort;
  final bool fromCache;
  final bool isRefreshing;

  FarmListState copyWith({
    List<Farm>? farms,
    int? total,
    int? page,
    int? pageSize,
    bool? hasMore,
    String? search,
    FarmFilter? filter,
    FarmSort? sort,
    bool? fromCache,
    bool? isRefreshing,
  }) {
    return FarmListState(
      farms: farms ?? this.farms,
      total: total ?? this.total,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      search: search ?? this.search,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
      fromCache: fromCache ?? this.fromCache,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

final farmSearchProvider = StateProvider<String>((ref) => '');
final farmFilterProvider = StateProvider<FarmFilter>((ref) => FarmFilter.all);
final farmSortProvider = StateProvider<FarmSort>((ref) => FarmSort.nameAsc);
final farmUploadProgressProvider = StateProvider.autoDispose<double?>(
  (ref) => null,
);

final activeFarmIdProvider =
    AsyncNotifierProvider<ActiveFarmIdNotifier, String?>(
      ActiveFarmIdNotifier.new,
    );

class ActiveFarmIdNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    return ref.read(farmRepositoryProvider).readActiveFarmId();
  }

  Future<void> setActive(String? farmId) async {
    await ref.read(farmRepositoryProvider).writeActiveFarmId(farmId);
    state = AsyncData(farmId);
  }
}

final farmListProvider = AsyncNotifierProvider<FarmListNotifier, FarmListState>(
  FarmListNotifier.new,
);

class FarmListNotifier extends AsyncNotifier<FarmListState> {
  bool _loadInFlight = false;

  @override
  Future<FarmListState> build() async {
    final cached = await ref.read(farmRepositoryProvider).readCachedFarmList();
    if (cached != null) {
      unawaited(refresh(silent: true));
      return _fromPage(cached, page: 1);
    }
    return _load(page: 1);
  }

  FarmListState _fromPage(FarmPageResult pageResult, {required int page}) {
    final search = ref.read(farmSearchProvider);
    final filter = ref.read(farmFilterProvider);
    final sort = ref.read(farmSortProvider);
    return FarmListState(
      farms: page == 1
          ? pageResult.farms
          : [...state.value?.farms ?? [], ...pageResult.farms],
      total: pageResult.total,
      page: pageResult.page,
      pageSize: pageResult.pageSize,
      hasMore: pageResult.hasMore,
      search: search,
      filter: filter,
      sort: sort,
      fromCache: pageResult.fromCache,
    );
  }

  Future<FarmListState> _load({
    required int page,
    bool forceRefresh = false,
  }) async {
    final search = ref.read(farmSearchProvider);
    final filter = ref.read(farmFilterProvider);
    final sort = ref.read(farmSortProvider);
    final result = await ref
        .read(farmRepositoryProvider)
        .listFarms(
          page: page,
          search: search,
          filter: filter,
          sort: sort,
          forceRefresh: forceRefresh,
        );
    return result.when(
      success: (pageResult) {
        if (pageResult.farms.length == 1) {
          unawaited(
            ref
                .read(activeFarmIdProvider.notifier)
                .setActive(pageResult.farms.first.id),
          );
        }
        return _fromPage(pageResult, page: page);
      },
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
    final previous = state.value ?? const FarmListState();
    if (!silent) {
      state = AsyncData(previous.copyWith(isRefreshing: true));
    }
    _loadInFlight = true;
    try {
      state = AsyncData(await _load(page: 1, forceRefresh: true));
    } catch (_) {
      if (previous.farms.isNotEmpty) {
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

  void applyQuery() {
    reload(forceRefresh: true);
  }

  Future<Farm?> saveOptimistic(FarmInput input, {String? farmId}) async {
    if (_loadInFlight) return null;
    _loadInFlight = true;
    final location = FarmLocation.fromAddress(
      input.address,
      areaLabel: input.areaLabel,
    );
    if (!location.canSaveFarm) {
      _loadInFlight = false;
      return null;
    }
    final optimistic = Farm(
      id: location.farmIdFor(existingFarmId: farmId),
      name: input.name,
      locationLabel: input.areaLabel ?? input.name,
      villageId: location.villageId ?? location.locationKey,
      animalCount: 0,
      activeAnimalCount: 0,
      address: location.toAddressDto(),
      coverPhotoUrl: input.coverPhotoUrl,
    );
    final current = state.value ?? const FarmListState();
    state = AsyncData(
      current.copyWith(
        farms: [
          optimistic,
          ...current.farms.where((f) => f.id != optimistic.id),
        ],
        total: 1,
      ),
    );
    try {
      final result = await ref
          .read(farmRepositoryProvider)
          .saveFarm(input, farmId: farmId);
      return await result.when(
        success: (farm) async {
          await ref.read(farmRepositoryProvider).clearDraft(farmId: farmId);
          state = AsyncData(current.copyWith(farms: [farm], total: 1));
          ref.invalidate(farmDetailProvider(farm.id));
          ref.invalidate(mobileMeProvider);
          ref.invalidate(dashboardProvider);
          invalidateDashboardSections(ref);
          await ref.read(activeFarmIdProvider.notifier).setActive(farm.id);
          return farm;
        },
        failure: (e) async {
          state = AsyncData(current);
          throw e;
        },
      );
    } finally {
      _loadInFlight = false;
    }
  }
}

final farmDetailProvider = FutureProvider.autoDispose
    .family<FarmDetail, String>((ref, id) async {
      final result = await ref.read(farmRepositoryProvider).getFarm(id);
      return result.when(success: (detail) => detail, failure: (e) => throw e);
    });
