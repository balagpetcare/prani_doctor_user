import 'offline_dto.dart';

/// Foreground/background sync orchestration for unreliable connectivity.
abstract class SyncCoordinatorContract {
  /// Drain pending queue when connectivity restores.
  Future<void> onConnectivityRestored();

  /// User-initiated sync (visible progress).
  Future<void> syncNow({bool foreground = true});

  /// Background batch — max 25 items, battery-aware interval ≥ 60s.
  Future<void> scheduleBackgroundSync();

  /// Pause/resume retry engine.
  Future<void> setPaused(bool paused);

  Stream<OfflineQueueUxState> get uxStateStream;
}
