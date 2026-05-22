import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/farm_dto.dart';
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
      fromCache: fromCache ?? this.fromCache,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

final farmSearchProvider = StateProvider<String>((ref) => '');
final farmFilterProvider = StateProvider<FarmFilter>((ref) => FarmFilter.all);
final farmUploadProgressProvider = StateProvider<double?>((ref) => null);

final farmListProvider =
    AsyncNotifierProvider<FarmListNotifier, FarmListState>(FarmListNotifier.new);

class FarmListNotifier extends AsyncNotifier<FarmListState> {
  bool _loadInFlight = false;

  @override
  Future<FarmListState> build() async {
    return _load(page: 1);
  }

  Future<FarmListState> _load({required int page, bool forceRefresh = false}) async {
    final search = ref.read(farmSearchProvider);
    final filter = ref.read(farmFilterProvider);
    final result = await ref.read(farmRepositoryProvider).listFarms(
          page: page,
          search: search,
          filter: filter,
          forceRefresh: forceRefresh,
        );
    return result.when(
      success: (pageResult) => FarmListState(
        farms: page == 1 ? pageResult.farms : [...state.value?.farms ?? [], ...pageResult.farms],
        total: pageResult.total,
        page: pageResult.page,
        pageSize: pageResult.pageSize,
        hasMore: pageResult.hasMore,
        search: search,
        filter: filter,
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
    final previous = state.value ?? const FarmListState();
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

  void applyQuery() {
    reload(forceRefresh: true);
  }

  Future<Farm?> saveOptimistic(FarmInput input, {String? farmId}) async {
    final villageId = input.address.villageId;
    if (villageId == null) return null;
    final optimistic = Farm(
      id: farmId ?? 'farm-$villageId',
      name: input.name,
      locationLabel: input.areaLabel ?? input.name,
      villageId: villageId,
      animalCount: 0,
      activeAnimalCount: 0,
      address: input.address,
    );
    final current = state.value ?? const FarmListState();
    state = AsyncData(
      current.copyWith(
        farms: [optimistic, ...current.farms.where((f) => f.id != optimistic.id)],
        total: 1,
      ),
    );
    final result = await ref.read(farmRepositoryProvider).saveFarm(input, farmId: farmId);
    return result.when(
      success: (farm) {
        state = AsyncData(current.copyWith(farms: [farm], total: 1));
        ref.invalidate(farmDetailProvider(farm.id));
        return farm;
      },
      failure: (e) {
        state = AsyncData(current);
        throw e;
      },
    );
  }
}

final farmDetailProvider = FutureProvider.autoDispose.family<FarmDetail, String>((ref, id) async {
  final result = await ref.read(farmRepositoryProvider).getFarm(id);
  return result.when(
    success: (detail) => detail,
    failure: (e) => throw e,
  );
});
