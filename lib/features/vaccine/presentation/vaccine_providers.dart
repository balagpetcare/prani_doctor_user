import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_result.dart';
import '../../../core/providers/provider_stability.dart';
import '../../../core/session/session_providers.dart';
import '../../notifications/local_notification_service.dart';
import '../data/vaccine_dto.dart';
import '../data/vaccine_reminder_service.dart';
import '../data/vaccine_repository.dart';

class VaccineListState {
  const VaccineListState({
    this.records = const [],
    this.total = 0,
    this.page = 1,
    this.hasMore = false,
    this.pendingSyncCount = 0,
    this.fromCache = false,
    this.isRefreshing = false,
  });

  final List<VaccineRecord> records;
  final int total;
  final int page;
  final bool hasMore;
  final int pendingSyncCount;
  final bool fromCache;
  final bool isRefreshing;

  VaccineListState copyWith({
    List<VaccineRecord>? records,
    int? total,
    int? page,
    bool? hasMore,
    int? pendingSyncCount,
    bool? fromCache,
    bool? isRefreshing,
  }) {
    return VaccineListState(
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

final vaccineSearchProvider = StateProvider.autoDispose<String>((ref) => '');
final vaccineAnimalFilterProvider = StateProvider.autoDispose<String?>((ref) => null);
final vaccineStatusFilterProvider = StateProvider.autoDispose<VaccineStatus?>(
  (ref) => null,
);
final vaccineFromDateProvider = StateProvider.autoDispose<DateTime?>(
  (ref) => null,
);
final vaccineToDateProvider = StateProvider.autoDispose<DateTime?>(
  (ref) => null,
);

List<VaccineRecord> applyVaccineClientFilters(
  List<VaccineRecord> records, {
  required String search,
  DateTime? from,
  DateTime? to,
  bool excludeCompleted = false,
}) {
  final query = search.trim().toLowerCase();
  return records.where((record) {
    if (excludeCompleted && record.status == VaccineStatus.completed) {
      return false;
    }
    if (from != null &&
        _dateOnly(record.scheduledDate).isBefore(_dateOnly(from))) {
      return false;
    }
    if (to != null && _dateOnly(record.scheduledDate).isAfter(_dateOnly(to))) {
      return false;
    }
    if (query.isEmpty) return true;
    return record.vaccineName.toLowerCase().contains(query) ||
        (record.animalName ?? '').toLowerCase().contains(query) ||
        (record.vaccineType ?? '').toLowerCase().contains(query);
  }).toList();
}

VaccineListState _fromPage(
  VaccinePageResult page, {
  required int pageNum,
  VaccineListState? previous,
}) {
  return VaccineListState(
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

final vaccineProvider =
    AsyncNotifierProvider<VaccineListNotifier, VaccineListState>(
      VaccineListNotifier.new,
    );

class VaccineListNotifier extends AsyncNotifier<VaccineListState> {
  bool _loadInFlight = false;

  @override
  Future<VaccineListState> build() async {
    if (!ref.watch(protectedApisEnabledProvider)) {
      return const VaccineListState();
    }
    final cached = await ref.read(vaccineRepositoryProvider).readCachedList();
    if (cached != null && cached.records.isNotEmpty) {
      unawaited(refresh(silent: true));
      return _fromPage(cached, pageNum: 1);
    }
    return _load(page: 1);
  }

  Future<VaccineListState> _load({
    required int page,
    bool forceRefresh = false,
  }) async {
    final result = await ref
        .read(vaccineRepositoryProvider)
        .listRecords(
          animalId: ref.read(vaccineAnimalFilterProvider),
          status: ref.read(vaccineStatusFilterProvider),
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
    final previous = state.value ?? const VaccineListState();
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

final vaccineHistoryProvider =
    AsyncNotifierProvider<VaccineHistoryNotifier, VaccineListState>(
      VaccineHistoryNotifier.new,
    );

class VaccineHistoryNotifier extends AsyncNotifier<VaccineListState> {
  bool _loadInFlight = false;

  @override
  Future<VaccineListState> build() async => _load(page: 1);

  Future<VaccineListState> _load({
    required int page,
    bool forceRefresh = false,
  }) async {
    final result = await ref
        .read(vaccineRepositoryProvider)
        .listRecords(
          animalId: ref.read(vaccineAnimalFilterProvider),
          status: VaccineStatus.completed,
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

  Future<void> refresh() async {
    if (_loadInFlight) return;
    final previous = state.value ?? const VaccineListState();
    state = AsyncData(previous.copyWith(isRefreshing: true));
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

final vaccineRecordProvider = FutureProvider.autoDispose
    .family<VaccineRecord, String>((ref, id) async {
      final result = await ref.read(vaccineRepositoryProvider).getRecord(id);
      return result.when(success: (r) => r, failure: (e) => throw e);
    });

final vaccineReminderProvider =
    FutureProvider.autoDispose<VaccineRemindersData>((ref) async {
      if (!ref.watch(protectedApisEnabledProvider)) {
        return const VaccineRemindersData(overdue: [], upcoming: []);
      }
      final repo = ref.read(vaccineRepositoryProvider);
      return loadWithCache(
        ref: ref,
        label: 'vaccineReminders',
        readCache: repo.readCachedReminders,
        fetch: () async {
          final result = await repo.getReminders();
          return result.when(success: (r) => r, failure: (e) => throw e);
        },
        revalidate: () async {
          final result = await repo.getReminders(forceRefresh: true);
          return result is ApiSuccess;
        },
      );
    });

final vaccineSummaryProvider = FutureProvider.autoDispose<VaccineSummaryData>((
  ref,
) async {
  if (!ref.watch(protectedApisEnabledProvider)) {
    return VaccineSummaryData.fromSources(
      allRecords: const [],
      reminders: const VaccineRemindersData(overdue: [], upcoming: []),
    );
  }
  final repo = ref.read(vaccineRepositoryProvider);
  final cachedList = await repo.readCachedList();
  final cachedReminders = await repo.readCachedReminders();
  if (cachedList != null && cachedReminders != null) {
    scheduleCacheRevalidate(
      ref,
      label: 'vaccineSummary',
      revalidate: () async {
        final results = await Future.wait([
          repo.listRecords(page: 1, limit: 100, forceRefresh: true),
          repo.getReminders(forceRefresh: true),
        ]);
        return results.every((r) => r is ApiSuccess);
      },
    );
    return VaccineSummaryData.fromSources(
      allRecords: cachedList.records,
      reminders: cachedReminders,
      fromCache: true,
    );
  }
  final listResult = await repo.listRecords(
    page: 1,
    limit: 100,
    forceRefresh: false,
  );
  final remindersResult = await repo.getReminders(forceRefresh: false);
  return listResult.when(
    success: (list) => remindersResult.when(
      success: (reminders) => VaccineSummaryData.fromSources(
        allRecords: list.records,
        reminders: reminders,
      ),
      failure: (e) => throw e,
    ),
    failure: (e) => throw e,
  );
});

final vaccineCalendarProvider =
    FutureProvider.autoDispose<List<VaccineCalendarDay>>((ref) async {
      if (!ref.watch(protectedApisEnabledProvider)) {
        return [];
      }
      ref.watch(vaccineFromDateProvider);
      ref.watch(vaccineToDateProvider);
      final repo = ref.read(vaccineRepositoryProvider);
      final cached = await repo.readCachedList();
      if (cached != null && cached.records.isNotEmpty) {
        scheduleCacheRevalidate(
          ref,
          label: 'vaccineCalendar',
          revalidate: () async {
            final result = await repo.listRecords(
              page: 1,
              limit: 100,
              forceRefresh: true,
            );
            return result is ApiSuccess;
          },
        );
        return _calendarDays(cached.records);
      }
      final result = await repo.listRecords(
        page: 1,
        limit: 100,
        forceRefresh: false,
      );
      return result.when(
        success: (page) => _calendarDays(page.records),
        failure: (e) => throw e,
      );
    });

List<VaccineCalendarDay> _calendarDays(List<VaccineRecord> records) {
  final grouped = <DateTime, List<VaccineRecord>>{};
  for (final record in records) {
    final key = _dateOnly(record.scheduledDate);
    grouped.putIfAbsent(key, () => []).add(record);
  }
  return grouped.entries
      .map((e) => VaccineCalendarDay(date: e.key, records: e.value))
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
}

final vaccineReminderServiceProvider = Provider<VaccineReminderService>((ref) {
  return VaccineReminderService(LocalNotificationService());
});
