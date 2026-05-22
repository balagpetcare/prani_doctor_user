import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    this.fromCache = false,
    this.isRefreshing = false,
  });

  final List<VaccineRecord> records;
  final int total;
  final int page;
  final bool hasMore;
  final bool fromCache;
  final bool isRefreshing;

  VaccineListState copyWith({
    List<VaccineRecord>? records,
    int? total,
    int? page,
    bool? hasMore,
    bool? fromCache,
    bool? isRefreshing,
  }) {
    return VaccineListState(
      records: records ?? this.records,
      total: total ?? this.total,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      fromCache: fromCache ?? this.fromCache,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

final vaccineStatusFilterProvider = StateProvider<VaccineStatus?>((ref) => null);

final vaccineProvider =
    AsyncNotifierProvider<VaccineListNotifier, VaccineListState>(VaccineListNotifier.new);

class VaccineListNotifier extends AsyncNotifier<VaccineListState> {
  bool _loadInFlight = false;

  @override
  Future<VaccineListState> build() async => _load(page: 1);

  Future<VaccineListState> _load({required int page, bool forceRefresh = false}) async {
    final result = await ref.read(vaccineRepositoryProvider).listRecords(
          page: page,
          status: ref.read(vaccineStatusFilterProvider),
          forceRefresh: forceRefresh,
        );
    return result.when(
      success: (pageResult) => VaccineListState(
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
    final previous = state.value ?? const VaccineListState();
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

final vaccineReminderServiceProvider = Provider<VaccineReminderService>((ref) {
  return VaccineReminderService(LocalNotificationService());
});

final vaccineReminderProvider = FutureProvider.autoDispose<VaccineRemindersData>((ref) async {
  final result = await ref.read(vaccineRepositoryProvider).getReminders();
  final reminders = result.when(success: (r) => r, failure: (e) => throw e);
  final service = ref.read(vaccineReminderServiceProvider);
  await service.scheduleFallbackNotifications(
    reminders,
    overdueTitle: 'Vaccine overdue',
    dueTitle: 'Vaccine due soon',
    upcomingBody: '{name} for {animal}',
  );
  return reminders;
});

final vaccineRecordProvider =
    FutureProvider.autoDispose.family<VaccineRecord, String>((ref, id) async {
  final result = await ref.read(vaccineRepositoryProvider).getRecord(id);
  return result.when(success: (r) => r, failure: (e) => throw e);
});
