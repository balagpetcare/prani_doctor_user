import 'offline_dto.dart';

/// HTTP contract for offline sync APIs (Android-first).
abstract class OfflineRepositoryContract {
  static const syncStatusPath = '/api/sync/status';
  static const syncPath = '/api/sync';
  static const syncRetryPath = '/api/sync/retry';
  static const offlineQueuePath = '/api/offline/queue';

  Future<SyncStatusDto> getSyncStatus({String? deviceId});

  Future<Map<String, dynamic>> sync({
    String? deviceId,
    OfflineConnectivityMode? connectivityMode,
    bool? manualOverride,
    String mode,
    List<SyncItemInput>? items,
  });

  Future<Map<String, dynamic>> retrySync({
    List<String>? idempotencyKeys,
    bool includeDead,
    bool pause,
    bool resume,
  });

  Future<Map<String, dynamic>> getOfflineQueue();
}
