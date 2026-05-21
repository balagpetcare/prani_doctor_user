import 'offline_dto.dart';

/// Connectivity probe — ONLINE / DEGRADED / OFFLINE.
abstract class ConnectivityContract {
  Stream<OfflineConnectivityMode> get modeStream;

  OfflineConnectivityMode get currentMode;

  /// Manual override for field testing (user-visible toggle).
  Future<void> setManualOverride(bool enabled);
}
