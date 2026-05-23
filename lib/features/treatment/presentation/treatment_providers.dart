import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notifications/local_notification_service.dart';
import '../data/treatment_dto.dart';
import '../data/treatment_follow_up_service.dart';
import '../data/treatment_repository.dart';

class TreatmentListState {
  const TreatmentListState({
    this.records = const [],
    this.total = 0,
    this.page = 1,
    this.hasMore = false,
    this.pendingSyncCount = 0,
    this.fromCache = false,
    this.isRefreshing = false,
  });

  final List<FarmTreatment> records;
  final int total;
  final int page;
  final bool hasMore;
  final int pendingSyncCount;
  final bool fromCache;
  final bool isRefreshing;

  TreatmentListState copyWith({
    List<FarmTreatment>? records,
    int? total,
    int? page,
    bool? hasMore,
    int? pendingSyncCount,
    bool? fromCache,
    bool? isRefreshing,
  }) {
    return TreatmentListState(
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

final treatmentSearchProvider = StateProvider<String>((ref) => '');
final treatmentStatusFilterProvider = StateProvider<TreatmentStatus?>(
  (ref) => null,
);
final treatmentAnimalFilterProvider = StateProvider<String?>((ref) => null);
final treatmentFromDateProvider = StateProvider<DateTime?>((ref) => null);
final treatmentToDateProvider = StateProvider<DateTime?>((ref) => null);

List<FarmTreatment> applyTreatmentDateFilter(
  List<FarmTreatment> records, {
  DateTime? from,
  DateTime? to,
}) {
  return records.where((record) {
    if (from != null && _dateOnly(record.startDate).isBefore(_dateOnly(from))) {
      return false;
    }
    if (to != null && _dateOnly(record.startDate).isAfter(_dateOnly(to))) {
      return false;
    }
    return true;
  }).toList();
}

TreatmentListState _fromPage(
  TreatmentPageResult page, {
  required int pageNum,
  TreatmentListState? previous,
}) {
  return TreatmentListState(
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

final treatmentProvider =
    AsyncNotifierProvider<TreatmentListNotifier, TreatmentListState>(
      TreatmentListNotifier.new,
    );

class TreatmentListNotifier extends AsyncNotifier<TreatmentListState> {
  bool _loadInFlight = false;

  @override
  Future<TreatmentListState> build() async {
    final cached = await ref.read(treatmentRepositoryProvider).readCachedList();
    if (cached != null && cached.records.isNotEmpty) {
      unawaited(refresh(silent: true));
      return _fromPage(cached, pageNum: 1);
    }
    return _load(page: 1);
  }

  Future<TreatmentListState> _load({
    required int page,
    bool forceRefresh = false,
  }) async {
    final result = await ref
        .read(treatmentRepositoryProvider)
        .listRecords(
          animalId: ref.read(treatmentAnimalFilterProvider),
          status: ref.read(treatmentStatusFilterProvider),
          search: ref.read(treatmentSearchProvider),
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
    final previous = state.value ?? const TreatmentListState();
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

final treatmentRecordProvider = FutureProvider.autoDispose
    .family<FarmTreatment, String>((ref, id) async {
      final result = await ref.read(treatmentRepositoryProvider).getRecord(id);
      return result.when(success: (r) => r, failure: (e) => throw e);
    });

final prescriptionProvider = FutureProvider.autoDispose
    .family<PrescriptionData, String>((ref, id) async {
      final treatment = await ref.watch(treatmentRecordProvider(id).future);
      return PrescriptionData(
        treatmentId: treatment.id,
        prescription: treatment.prescription,
        medicines: treatment.medicines,
        fromCache: treatment.fromCache,
      );
    });

final treatmentSummaryProvider =
    FutureProvider.autoDispose<TreatmentSummaryData>((ref) async {
      final repo = ref.read(treatmentRepositoryProvider);
      final cached = await repo.readCachedList();
      if (cached != null && cached.records.isNotEmpty) {
        return TreatmentSummaryData.fromRecords(
          cached.records,
          fromCache: true,
        );
      }
      final result = await repo.listRecords(
        page: 1,
        limit: 100,
        forceRefresh: false,
      );
      return result.when(
        success: (page) => TreatmentSummaryData.fromRecords(page.records),
        failure: (e) => throw e,
      );
    });

final treatmentTimelineProvider =
    FutureProvider.autoDispose<List<TreatmentTimelineGroup>>((ref) async {
      final repo = ref.read(treatmentRepositoryProvider);
      final cached = await repo.readCachedList();
      Future<List<FarmTreatment>> loadRecords() async {
        if (cached != null && cached.records.isNotEmpty) {
          return cached.records;
        }
        final result = await repo.listRecords(
          page: 1,
          limit: 100,
          forceRefresh: false,
        );
        return result.when(success: (p) => p.records, failure: (e) => throw e);
      }

      final records = await loadRecords();
      final grouped = <String, List<FarmTreatment>>{};
      for (final record in records) {
        final month = record.startDate.toIso8601String().substring(0, 7);
        grouped.putIfAbsent(month, () => []).add(record);
      }
      return grouped.entries
          .map((e) => TreatmentTimelineGroup(month: e.key, records: e.value))
          .toList()
        ..sort((a, b) => b.month.compareTo(a.month));
    });

final treatmentMedicinePlanProvider =
    FutureProvider.autoDispose<List<TreatmentMedicinePlanItem>>((ref) async {
      final repo = ref.read(treatmentRepositoryProvider);
      final result = await repo.listRecords(
        status: TreatmentStatus.active,
        page: 1,
        limit: 100,
        forceRefresh: false,
      );
      return result.when(
        success: (page) {
          final items = <TreatmentMedicinePlanItem>[];
          for (final treatment in page.records) {
            for (final medicine in treatment.medicines) {
              items.add(
                TreatmentMedicinePlanItem(
                  treatment: treatment,
                  medicine: medicine,
                ),
              );
            }
          }
          return items;
        },
        failure: (e) => throw e,
      );
    });

final treatmentFollowUpProvider =
    FutureProvider.autoDispose<List<FarmTreatment>>((ref) async {
      final repo = ref.read(treatmentRepositoryProvider);
      final result = await repo.listRecords(
        status: TreatmentStatus.active,
        page: 1,
        limit: 100,
        forceRefresh: false,
      );
      final now = DateTime.now();
      return result.when(
        success: (page) =>
            page.records.where((r) {
                if (r.endDate == null) return false;
                return r.endDate!.isBefore(now.add(const Duration(days: 14)));
              }).toList()
              ..sort((a, b) => (a.endDate ?? now).compareTo(b.endDate ?? now)),
        failure: (e) => throw e,
      );
    });

final treatmentFollowUpServiceProvider = Provider<TreatmentFollowUpService>((
  ref,
) {
  return TreatmentFollowUpService(LocalNotificationService());
});
