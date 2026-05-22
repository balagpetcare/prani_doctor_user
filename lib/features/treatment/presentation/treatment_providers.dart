import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/treatment_dto.dart';
import '../data/treatment_repository.dart';

class TreatmentListState {
  const TreatmentListState({
    this.records = const [],
    this.total = 0,
    this.page = 1,
    this.hasMore = false,
    this.fromCache = false,
    this.isRefreshing = false,
  });

  final List<FarmTreatment> records;
  final int total;
  final int page;
  final bool hasMore;
  final bool fromCache;
  final bool isRefreshing;

  TreatmentListState copyWith({
    List<FarmTreatment>? records,
    int? total,
    int? page,
    bool? hasMore,
    bool? fromCache,
    bool? isRefreshing,
  }) {
    return TreatmentListState(
      records: records ?? this.records,
      total: total ?? this.total,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      fromCache: fromCache ?? this.fromCache,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

final treatmentSearchProvider = StateProvider<String>((ref) => '');
final treatmentStatusFilterProvider = StateProvider<TreatmentStatus?>((ref) => null);

final treatmentProvider =
    AsyncNotifierProvider<TreatmentListNotifier, TreatmentListState>(TreatmentListNotifier.new);

class TreatmentListNotifier extends AsyncNotifier<TreatmentListState> {
  bool _loadInFlight = false;

  @override
  Future<TreatmentListState> build() async => _load(page: 1);

  Future<TreatmentListState> _load({required int page, bool forceRefresh = false}) async {
    final result = await ref.read(treatmentRepositoryProvider).listRecords(
          page: page,
          search: ref.read(treatmentSearchProvider),
          status: ref.read(treatmentStatusFilterProvider),
          forceRefresh: forceRefresh,
        );
    return result.when(
      success: (pageResult) => TreatmentListState(
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
    final previous = state.value ?? const TreatmentListState();
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

final treatmentRecordProvider =
    FutureProvider.autoDispose.family<FarmTreatment, String>((ref, id) async {
  final result = await ref.read(treatmentRepositoryProvider).getRecord(id);
  return result.when(success: (r) => r, failure: (e) => throw e);
});

final prescriptionProvider =
    FutureProvider.autoDispose.family<PrescriptionData, String>((ref, id) async {
  final treatment = await ref.watch(treatmentRecordProvider(id).future);
  return PrescriptionData(
    treatmentId: treatment.id,
    prescription: treatment.prescription,
    medicines: treatment.medicines,
    fromCache: treatment.fromCache,
  );
});
