/// Local Hive/offline cache contract for area hierarchy.
///
/// Keys are versioned to allow invalidation when seed version changes.
abstract class AreaCacheContract {
  static const boxName = 'area_engine_cache_v1';

  static String divisionsKey(String locale) => 'divisions:$locale';
  static String districtsKey(String divisionId, String locale) => 'districts:$divisionId:$locale';
  static String upazilasKey(String districtId, String locale) => 'upazilas:$districtId:$locale';
  static String unionsKey(String upazilaId, String locale) => 'unions:$upazilaId:$locale';
  static String villagesKey(String unionId, String locale) => 'villages:$unionId:$locale';
  static String searchKey(String hash) => 'search:$hash';
  static const seedVersionKey = 'seed_version';
  static const divisionsKeyBn = 'divisions:bn';

  /// Recommended TTL for offline reads (7 days) — refresh on app startup if stale.
  static const offlineTtl = Duration(days: 7);

  Future<void> writeJson(String key, Map<String, dynamic> payload);

  Future<Map<String, dynamic>?> readJson(String key);

  Future<void> clearHierarchy();

  Future<void> setSeedVersion(String version);

  Future<String?> getSeedVersion();
}

/// Offline readiness checklist for Flutter integrators.
abstract class AreaOfflineReadiness {
  static const requiredKeys = [
    AreaCacheContract.seedVersionKey,
    AreaCacheContract.divisionsKeyBn,
  ];

  static bool isWarm(Map<String, dynamic> cacheSnapshot) {
    return cacheSnapshot.containsKey(AreaCacheContract.divisionsKeyBn);
  }
}
