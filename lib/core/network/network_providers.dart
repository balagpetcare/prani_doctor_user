import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_env.dart';
import '../../features/offline/data/connectivity_service.dart';
import '../../features/offline/offline_providers.dart';
import '../../features/offline/data/sync_coordinator.dart';
import '../session/session_controller.dart';
import 'network_service.dart';

final appEnvProvider = Provider<AppEnv>((ref) => AppEnv.fromEnvironment());

final networkServiceProvider = Provider<NetworkService>((ref) {
  return NetworkService(
    ref.watch(appEnvProvider),
    ref.read(sessionControllerProvider.notifier),
  );
});

final networkDiagnosticsProvider =
    AsyncNotifierProvider<NetworkDiagnosticsNotifier, NetworkDiagnostics?>(
      NetworkDiagnosticsNotifier.new,
    );

class NetworkDiagnosticsNotifier extends AsyncNotifier<NetworkDiagnostics?> {
  Future<void>? _inFlight;

  @override
  Future<NetworkDiagnostics?> build() async => null;

  Future<void> runChecks({bool reconnect = false}) async {
    if (_inFlight != null) {
      await _inFlight;
      return;
    }
    state = const AsyncLoading();
    final future = _execute(reconnect: reconnect);
    _inFlight = future;
    try {
      state = AsyncData(await future);
    } catch (e, st) {
      state = AsyncError(e, st);
    } finally {
      _inFlight = null;
    }
  }

  Future<NetworkDiagnostics> _execute({required bool reconnect}) async {
    if (reconnect) {
      await ref.read(syncCoordinatorProvider).syncNow(foreground: true);
    }
    final connectivity = ref.read(connectivityServiceProvider);
    final online = isOnlineMode(connectivity.currentMode);
    return ref
        .read(networkServiceProvider)
        .runDiagnostics(deviceOnline: online);
  }
}
