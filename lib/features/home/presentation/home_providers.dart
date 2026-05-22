import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/offline/network_errors.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/session/session_state.dart';
import '../../notifications/data/notification_repository.dart';
import '../../service_requests/data/service_request_repository.dart';
import '../data/dashboard_context_dto.dart';
import '../data/dashboard_repository.dart';

const dashboardPollInterval = Duration(seconds: 60);

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

final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardContext?>(DashboardNotifier.new);

class DashboardNotifier extends AsyncNotifier<DashboardContext?> {
  bool _reloadInFlight = false;
  bool _refreshInFlight = false;

  @override
  Future<DashboardContext?> build() async {
    final authed = ref.watch(
      sessionControllerProvider.select((s) => s.isAuthenticated),
    );
    if (!authed) return null;
    return _load(forceRefresh: false);
  }

  Future<DashboardContext?> _load({required bool forceRefresh}) async {
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
  }

  Future<void> reload({bool forceRefresh = false}) async {
    if (_reloadInFlight) return;
    _reloadInFlight = true;
    state = const AsyncLoading();
    try {
      final data = await _load(forceRefresh: forceRefresh);
      state = AsyncData(data);
    } catch (e, st) {
      state = AsyncError(e, st);
    } finally {
      _reloadInFlight = false;
    }
  }

  /// Pull-to-refresh and background poll — keeps prior data visible.
  Future<void> refresh({bool silent = false}) async {
    if (_refreshInFlight || _reloadInFlight) return;
    _refreshInFlight = true;
    final previous = state.value;
    if (!silent && previous != null) {
      state = AsyncData(previous);
    }
    try {
      final data = await _load(forceRefresh: true);
      state = AsyncData(data);
      ref.invalidate(dashboardSummaryProvider);
    } catch (_) {
      if (previous != null) {
        state = AsyncData(previous);
      }
    } finally {
      _refreshInFlight = false;
    }
  }
}

final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  final dashboardAsync = ref.watch(dashboardProvider);
  final context = dashboardAsync.maybeWhen(data: (v) => v, orElse: () => null);
  if (context == null) {
    final cached = await ref.read(dashboardRepositoryProvider).readCachedDashboard();
    if (cached == null) return DashboardSummary.empty;
    return _buildSummary(ref, cached);
  }
  return _buildSummary(ref, context);
});

Future<DashboardSummary> _buildSummary(Ref ref, DashboardContext context) async {
  var activeAppointments = 0;
  var unreadNotifications = 0;

  final requestsResult =
      await ref.read(serviceRequestRepositoryProvider).listRequests(limit: 100);
  requestsResult.when(
    success: (data) {
      activeAppointments =
          data.requests.where((r) => r.status.isActive).length;
    },
    failure: (_) {},
  );

  final notificationsResult =
      await ref.read(notificationRepositoryProvider).getUnreadCount();
  notificationsResult.when(
    success: (count) => unreadNotifications = count,
    failure: (_) {},
  );

  final farm = context.farmSummary;
  return DashboardSummary(
    context: context,
    totalFarms: farm?.totalFarms ?? 0,
    totalAnimals: farm?.animalCount ?? 0,
    activeAppointments: activeAppointments,
    unreadNotifications: unreadNotifications,
    fromCache: context.fromCache,
  );
}

class DashboardPollNotifier extends Notifier<int> {
  Timer? _timer;
  bool _pollInFlight = false;

  @override
  int build() {
    ref.onDispose(_stop);
    ref.listen<SessionState>(sessionControllerProvider, (previous, next) {
      if (next.isAuthenticated) {
        start();
      } else {
        _stop();
      }
    }, fireImmediately: true);
    return 0;
  }

  void start() {
    if (!ref.read(sessionControllerProvider).isAuthenticated) return;
    _timer?.cancel();
    _timer = Timer.periodic(dashboardPollInterval, (_) => _poll());
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _poll() async {
    if (_pollInFlight) return;
    if (!ref.read(sessionControllerProvider).isAuthenticated) return;
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
