/// Encrypted token storage + cache separation (Android first).
abstract class OfflineStorageContract {
  static const secureBoxHint = 'flutter_secure_storage';
  static const cacheBoxName = 'offline_cache_v1';
  static const queueBoxName = 'offline_queue_v1';
  static const cacheQuotaBytes = 32 * 1024 * 1024;

  /// Tokens only in secure storage — never Hive/plain text.
  Future<void> writeSecure(String key, String value);

  Future<String?> readSecure(String key);

  Future<void> deleteSecure(String key);

  Future<void> writeCache(String key, Map<String, dynamic> payload);

  Future<Map<String, dynamic>?> readCache(String key);

  Future<void> enqueuePayload(String idempotencyKey, Map<String, dynamic> payload);

  Future<List<Map<String, dynamic>>> listQueuedPayloads();
}
