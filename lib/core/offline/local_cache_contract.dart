/// Local cache keys + TTL for offline-first reads.
abstract class LocalCacheContract {
  static const boxName = 'local_cache_v1';

  static const authSnapshotKey = 'auth_snapshot';
  static const profileKey = 'profile_snapshot';
  static String areaSeedKey(String locale) => 'area_seed:$locale';
  static String caseDraftKey(String caseId) => 'case_draft:$caseId';
  static String voiceDraftKey(String sessionId) => 'voice_draft:$sessionId';

  static const authTtl = Duration(hours: 24);
  static const areaTtl = Duration(days: 7);
  static const caseDraftTtl = Duration(days: 30);
  static const voiceDraftTtl = Duration(days: 7);
  static const profileTtl = Duration(hours: 24);

  Future<void> write(String key, Map<String, dynamic> payload, Duration ttl);

  Future<Map<String, dynamic>?> read(String key);

  Future<void> evictExpired();

  /// Never evict keys listed in pending sync queue.
  Future<void> evictLru({required Set<String> protectedKeys, required int quotaBytes});
}
