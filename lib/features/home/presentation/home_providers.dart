import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/offline/network_errors.dart';
import '../../../core/network/auto_refresh_guard.dart';
import '../../../core/providers/provider_stability.dart';
import '../../../core/session/session_providers.dart';
import '../../farm/data/farm_repository.dart';
import '../../notifications/data/notification_dto.dart';
import '../../notifications/data/notification_repository.dart';
import '../../service_requests/data/service_request_dto.dart';
import '../../service_requests/data/service_request_repository.dart';
import '../../vaccine/data/vaccine_dto.dart';
import '../../vaccine/data/vaccine_repository.dart';
import '../data/dashboard_context_dto.dart';
import '../data/dashboard_repository.dart';
import 'home_state.dart';
import 'providers/home_section_providers.dart';

const dashboardPollInterval = Duration(seconds: 60);
const dashboardCacheRefreshTtl = Duration(seconds: 90);
const dashboardBackgroundRetryDelay = Duration(seconds: 5);

final _dashboardDeduper = RequestDeduper();
final _sectionInvalidateDebouncer = RefreshDebouncer(
  delay: const Duration(milliseconds: 800),
);

class DashboardSummary {
  const DashboardSummary({
    required this.context,
    required this.totalFarms,
    required this.totalAnimals,
    required this.activeAppointments,
    required this.unreadNotifications,
    this.fromCache = false,
  });

  final DashboardContext context;
  final int totalFarms;
  final int totalAnimals;
  final int activeAppointments;
  final int unreadNotifications;
  final bool fromCache;

  static const empty = DashboardSummary(
    context: DashboardContext(
      dashboardType: DashboardType.general,
      user: DashboardContextUser(id: '', name: '', phone: '', email: ''),
    ),
    totalFarms: 0,
    totalAnimals: 0,
    activeAppointments: 0,
    unreadNotifications: 0,
  );
}

class DashboardMetrics {
  const DashboardMetrics({
    required this.totalFarms,
    required this.totalAnimals,
    required this.activeAppointments,
    required this.unreadNotifications,
    this.fromCache = false,
  });

  final int totalFarms;
  final int totalAnimals;
  final int activeAppointments;
  final int unreadNotifications;
  final bool fromCache;

  static const empty = DashboardMetrics(
    totalFarms: 0,
    totalAnimals: 0,
    activeAppointments: 0,
    unreadNotifications: 0,
  );
}

class DashboardAppointmentsSection {
  const DashboardAppointmentsSection({
    required this.appointments,
    required this.totalActive,
    this.fromCache = false,
  });

  final List<ServiceRequestDto> appointments;
  final int totalActive;
  final bool fromCache;

  bool get isEmpty => appointments.isEmpty;

  static const empty = DashboardAppointmentsSection(
    appointments: [],
    totalActive: 0,
  );
}

class DashboardActivitySection {
  const DashboardActivitySection({
    required this.notifications,
    this.fromCache = false,
  });

  final List<MobileNotificationDto> notifications;
  final bool fromCache;

  bool get isEmpty => notifications.isEmpty;

  static const empty = DashboardActivitySection(notifications: []);
}

class DashboardHealthAlertsSection {
  const DashboardHealthAlertsSection({
    required this.overdue,
    required this.upcoming,
    this.fromCache = false,
  });

  final List<VaccineRecord> overdue;
  final List<VaccineRecord> upcoming;
  final bool fromCache;

  int get totalAlerts => overdue.length + upcoming.length;

  bool get isEmpty => totalAlerts == 0;

  static const empty = DashboardHealthAlertsSection(overdue: [], upcoming: []);
}

final homeStateProvider = NotifierProvider<HomeStateNotifier, HomeState>(
  HomeStateNotifier.new,
);

class HomeStateNotifier extends Notifier<HomeState> {
  DateTime? _lastBackgroundRefresh;

  @override
  HomeState build() => HomeState.loading;

  void set(HomeState next) {
    if (state != next) state = next;
  }

  bool tryScheduleBackgroundRefresh() {
    final last = _lastBackgroundRefresh;
    final now = DateTime.now();
    if (last != null && now.difference(last) < dashboardCacheRefreshTtl) {
      return false;
    }
    _lastBackgroundRefresh = now;
    return true;
  }
}

final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardContext?>(
      DashboardNotifier.new,
    );

class DashboardNotifier extends AsyncNotifier<DashboardContext?>
    with AsyncRefreshGuard {
  @override
  Future<DashboardContext?> build() async {
    ref.persistProvider('dashboard');
    if (!ref.watch(protectedApisEnabledProvider)) return null;

    final cached = await ref
        .read(dashboardRepositoryProvider)
        .readCachedDashboard();
    if (cached != null) {
      ProviderLog.cache('dashboard context');
      ref.read(homeStateProvider.notifier).set(
        cached.fromCache ? HomeState.cached : HomeState.ready,
      );
      _scheduleBackgroundRefresh();
      return cached;
    }
    ref.read(homeStateProvider.notifier).set(HomeState.loading);
    return _load(forceRefresh: false);
  }

  void _scheduleBackgroundRefresh() {
    final homeState = ref.read(homeStateProvider.notifier);
    if (!homeState.tryScheduleBackgroundRefresh()) return;
    Future<void>.delayed(dashboardBackgroundRetryDelay, () async {
      await refresh(silent: true, allowBackground: true);
    });
  }

  Future<DashboardContext?> _load({required bool forceRefresh}) async {
    return _dashboardDeduper.run('dashboard.load', () async {
      final result = await ref
          .read(dashboardRepositoryProvider)
          .getDashboardContext(forceRefresh: forceRefresh);
      return result.when(
        success: (data) => data,
        failure: (error) {
          if (error.code == '401' || error.code == '403') throw error;
          throw error;
        },
      );
    });
  }

  Future<void> reload({bool forceRefresh = false}) async {
    if (!guardReload()) return;
    final previous = state.valueOrNull;
    if (previous == null) {
      ref.read(homeStateProvider.notifier).set(HomeState.loading);
      state = const AsyncLoading();
    }
    try {
      final data = await _load(forceRefresh: forceRefresh);
      state = AsyncData(data);
      ref.read(homeStateProvider.notifier).set(HomeState.ready);
      scheduleInvalidateDashboardSections(ref);
    } catch (e, st) {
      if (previous != null) {
        state = AsyncData(previous);
        ref.read(homeStateProvider.notifier).set(HomeState.offline);
      } else {
        state = AsyncError(e, st);
        ref.read(homeStateProvider.notifier).set(HomeState.error);
      }
    } finally {
      endReload();
    }
  }

  /// Pull-to-refresh and background poll — keeps prior data visible.
  Future<void> refresh({
    bool silent = false,
    bool invalidateSections = false,
    bool allowBackground = false,
  }) async {
    if (!allowBackground && !guardRefresh(silent: silent)) return;
    if (allowBackground && anyRefreshInFlight) return;
    if (allowBackground) refreshInFlight = true;
    final previous = state.value;
    if (!silent && previous != null) {
      state = AsyncData(previous);
    }
    try {
      final data = await _load(forceRefresh: true);
      state = AsyncData(data);
      ref.read(homeStateProvider.notifier).set(
        data?.fromCache == true ? HomeState.cached : HomeState.ready,
      );
      ref.read(autoRefreshGuardProvider.notifier).recordApiSuccess();
      if (invalidateSections) {
        scheduleInvalidateDashboardSections(ref);
      }
    } catch (_) {
      ref.read(autoRefreshGuardProvider.notifier).recordApiFailure();
      if (previous != null) {
        state = AsyncData(previous);
        ref.read(homeStateProvider.notifier).set(HomeState.offline);
      }
    } finally {
      endRefresh();
    }
  }
}

final dashboardMetricsProvider = FutureProvider<DashboardMetrics>((ref) async {
  ref.persistProvider('dashboardMetrics');
  if (!ref.watch(protectedApisEnabledProvider)) {
    return DashboardMetrics.empty;
  }
  final context = ref.watch(dashboardProvider).valueOrNull;
  if (context == null) {
    final cached = await ref
        .read(dashboardRepositoryProvider)
        .readCachedDashboard();
    if (cached == null) return DashboardMetrics.empty;
    return _loadMetrics(ref, cached);
  }
  return _dashboardDeduper.run(
    'dashboard.metrics',
    () => _loadMetrics(ref, context),
  );
});

Future<DashboardMetrics> _loadMetrics(Ref ref, DashboardContext context) async {
  var totalFarms = context.farmSummary?.totalFarms ?? 0;
  var totalAnimals = context.farmSummary?.animalCount ?? 0;
  var activeAppointments = 0;
  var unreadNotifications = 0;
  var fromCache = context.fromCache;

  final farmResult = await ref
      .read(farmRepositoryProvider)
      .listFarms(pageSize: 1);
  farmResult.when(
    success: (page) {
      totalFarms = page.total;
      fromCache = fromCache || page.fromCache;
    },
    failure: (_) {},
  );

  final requestsResult = await ref
      .read(serviceRequestRepositoryProvider)
      .listRequests(limit: 100);
  requestsResult.when(
    success: (data) {
      activeAppointments = data.requests.where((r) => r.status.isActive).length;
    },
    failure: (_) {},
  );

  final notificationsResult = await ref
      .read(notificationRepositoryProvider)
      .getUnreadCount();
  notificationsResult.when(
    success: (count) => unreadNotifications = count,
    failure: (_) {},
  );

  return DashboardMetrics(
    totalFarms: totalFarms,
    totalAnimals: totalAnimals,
    activeAppointments: activeAppointments,
    unreadNotifications: unreadNotifications,
    fromCache: fromCache,
  );
}

final dashboardAppointmentsProvider =
    FutureProvider<DashboardAppointmentsSection>((ref) async {
      ref.persistProvider('dashboardAppointments');
      if (!ref.watch(protectedApisEnabledProvider)) {
        return DashboardAppointmentsSection.empty;
      }
      return _dashboardDeduper.run('dashboard.appointments', () async {
        try {
          final result = await ref
              .read(serviceRequestRepositoryProvider)
              .listRequests(limit: 30);
          return result.when(
            success: (data) {
              final active =
                  data.requests.where((r) => r.status.isActive).toList()
                    ..sort(_compareAppointments);
              return DashboardAppointmentsSection(
                appointments: active.take(5).toList(),
                totalActive: active.length,
              );
            },
            failure: (_) => DashboardAppointmentsSection.empty,
          );
        } catch (_) {
          return DashboardAppointmentsSection.empty;
        }
      });
    });

int _compareAppointments(ServiceRequestDto a, ServiceRequestDto b) {
  final aTime = a.scheduledStart ?? a.preferredTime ?? a.createdAt ?? '';
  final bTime = b.scheduledStart ?? b.preferredTime ?? b.createdAt ?? '';
  return aTime.compareTo(bTime);
}

final dashboardActivityProvider = FutureProvider<DashboardActivitySection>((
  ref,
) async {
  ref.persistProvider('dashboardActivity');
  if (!ref.watch(protectedApisEnabledProvider)) {
    return DashboardActivitySection.empty;
  }
  return _dashboardDeduper.run('dashboard.activity', () async {
    try {
      final result = await ref
          .read(notificationRepositoryProvider)
          .listNotifications(limit: 5, offset: 0);
      return result.when(
        success: (page) => DashboardActivitySection(
          notifications: page.items,
          fromCache: page.fromCache,
        ),
        failure: (_) => DashboardActivitySection.empty,
      );
    } catch (_) {
      return DashboardActivitySection.empty;
    }
  });
});

final dashboardHealthAlertsProvider =
    FutureProvider<DashboardHealthAlertsSection>((ref) async {
      ref.persistProvider('dashboardHealthAlerts');
      if (!ref.watch(protectedApisEnabledProvider)) {
        return DashboardHealthAlertsSection.empty;
      }
      if (ref.watch(dashboardProvider).valueOrNull?.dashboardType ==
          DashboardType.aiTechnician) {
        return DashboardHealthAlertsSection.empty;
      }
      return _dashboardDeduper.run('dashboard.healthAlerts', () async {
        try {
          final result = await ref
              .read(vaccineRepositoryProvider)
              .getReminders();
          return result.when(
            success: (data) => DashboardHealthAlertsSection(
              overdue: data.overdue.take(3).toList(),
              upcoming: data.upcoming.take(2).toList(),
              fromCache: data.fromCache,
            ),
            failure: (_) => DashboardHealthAlertsSection.empty,
          );
        } catch (_) {
          return DashboardHealthAlertsSection.empty;
        }
      });
    });

/// Legacy aggregate — kept for tests; prefer section providers in UI.
final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  ref.persistProvider('dashboardSummary');
  final context = ref.watch(dashboardProvider).valueOrNull;
  if (context == null) {
    final cached = await ref
        .read(dashboardRepositoryProvider)
        .readCachedDashboard();
    if (cached == null) return DashboardSummary.empty;
    final metrics = await ref.watch(dashboardMetricsProvider.future);
    return DashboardSummary(
      context: cached,
      totalFarms: metrics.totalFarms,
      totalAnimals: metrics.totalAnimals,
      activeAppointments: metrics.activeAppointments,
      unreadNotifications: metrics.unreadNotifications,
      fromCache: cached.fromCache || metrics.fromCache,
    );
  }
  final metrics = await ref.watch(dashboardMetricsProvider.future);
  return DashboardSummary(
    context: context,
    totalFarms: metrics.totalFarms,
    totalAnimals: metrics.totalAnimals,
    activeAppointments: metrics.activeAppointments,
    unreadNotifications: metrics.unreadNotifications,
    fromCache: context.fromCache || metrics.fromCache,
  );
});

void scheduleInvalidateDashboardSections(Ref ref) {
  _sectionInvalidateDebouncer.schedule(() async {
    ProviderLog.provider('invalidate dashboard sections');
    ref.invalidate(dashboardMetricsProvider);
    ref.invalidate(dashboardAppointmentsProvider);
    ref.invalidate(dashboardActivityProvider);
    ref.invalidate(dashboardHealthAlertsProvider);
    ref.invalidate(dashboardSummaryProvider);
    invalidateHomeSections(ref);
  });
}

/// Immediate invalidation for pull-to-refresh / user actions.
void invalidateDashboardSections(Ref ref) {
  ref.invalidate(dashboardMetricsProvider);
  ref.invalidate(dashboardAppointmentsProvider);
  ref.invalidate(dashboardActivityProvider);
  ref.invalidate(dashboardHealthAlertsProvider);
  ref.invalidate(dashboardSummaryProvider);
  invalidateHomeSections(ref);
}

class DashboardPollNotifier extends Notifier<int> {
  Timer? _timer;
  bool _pollInFlight = false;
  bool _started = false;

  @override
  int build() {
    ref.persistProvider('dashboardPoll');
    ref.onDispose(_stop);
    ref.listen<bool>(protectedApisEnabledProvider, (previous, next) {
      if (next) {
        start();
      } else {
        _stop();
      }
    }, fireImmediately: true);
    return 0;
  }

  void start() {
    // Automatic dashboard polling disabled — refresh only on pull-to-refresh,
    // manual retry, or app resume (60s+).
    if (_started) return;
    _started = true;
    ProviderLog.provider('dashboard poll disabled (offline-first)');
  }

  void _stop() {
    _started = false;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _poll() async {
    if (_pollInFlight) return;
    if (!ref.read(protectedApisEnabledProvider)) return;
    _pollInFlight = true;
    try {
      await ref.read(dashboardProvider.notifier).refresh(silent: true);
    } finally {
      _pollInFlight = false;
    }
  }
}

final dashboardPollProvider = NotifierProvider<DashboardPollNotifier, int>(
  DashboardPollNotifier.new,
);

bool isDashboardUnauthorized(Object error) {
  if (error is AppException) {
    return error.code == '401' || error.code == '403';
  }
  return false;
}

bool isDashboardOffline(Object error) {
  if (error is AppException) {
    return isTransientNetworkError(error);
  }
  return false;
}

bool isCustomerDashboard(DashboardContext context) =>
    context.dashboardType != DashboardType.aiTechnician;
