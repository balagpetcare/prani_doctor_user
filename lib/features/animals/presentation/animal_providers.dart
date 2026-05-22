import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/animal_dto.dart';
import '../data/animal_repository.dart';

class AnimalListState {
  const AnimalListState({
    this.animals = const [],
    this.total = 0,
    this.page = 1,
    this.hasMore = false,
    this.fromCache = false,
    this.isRefreshing = false,
  });

  final List<AnimalProfile> animals;
  final int total;
  final int page;
  final bool hasMore;
  final bool fromCache;
  final bool isRefreshing;

  AnimalListState copyWith({
    List<AnimalProfile>? animals,
    int? total,
    int? page,
    bool? hasMore,
    bool? fromCache,
    bool? isRefreshing,
  }) {
    return AnimalListState(
      animals: animals ?? this.animals,
      total: total ?? this.total,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      fromCache: fromCache ?? this.fromCache,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

final animalSearchProvider = StateProvider<String>((ref) => '');
final animalFilterProvider = StateProvider<AnimalFilter>((ref) => AnimalFilter.all);
final animalUploadProgressProvider = StateProvider<double?>((ref) => null);

final animalListProvider =
    AsyncNotifierProvider<AnimalListNotifier, AnimalListState>(AnimalListNotifier.new);

class AnimalListNotifier extends AsyncNotifier<AnimalListState> {
  bool _loadInFlight = false;

  @override
  Future<AnimalListState> build() async => _load(page: 1);

  Future<AnimalListState> _load({required int page, bool forceRefresh = false}) async {
    final result = await ref.read(animalRepositoryProvider).listAnimals(
          page: page,
          search: ref.read(animalSearchProvider),
          filter: ref.read(animalFilterProvider),
          forceRefresh: forceRefresh,
        );
    return result.when(
      success: (pageResult) => AnimalListState(
        animals: page == 1
            ? pageResult.animals
            : [...state.value?.animals ?? [], ...pageResult.animals],
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
    final previous = state.value ?? const AnimalListState();
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

final animalDetailProvider =
    FutureProvider.autoDispose.family<AnimalDetail, String>((ref, id) async {
  final result = await ref.read(animalRepositoryProvider).getAnimal(id);
  return result.when(
    success: (detail) => detail,
    failure: (e) => throw e,
  );
});
