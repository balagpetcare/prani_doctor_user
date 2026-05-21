import '../../../core/cache/cache_store.dart';
import '../../../core/area/area_cache_contract.dart';

class AreaCacheStore implements AreaCacheContract {
  AreaCacheStore(this._cache);

  final CacheStore _cache;

  @override
  Future<void> writeJson(String key, Map<String, dynamic> payload) async {
    await _cache.put(key, payload);
  }

  @override
  Future<Map<String, dynamic>?> readJson(String key) async {
    final value = _cache.read<Map<dynamic, dynamic>>(key);
    if (value == null) return null;
    return value.map((k, v) => MapEntry(k.toString(), v));
  }

  @override
  Future<void> clearHierarchy() async {
    // Keys are versioned and expire via TTL on read; no bulk key listing in CacheStore.
  }

  @override
  Future<void> setSeedVersion(String version) async {
    await _cache.put(AreaCacheContract.seedVersionKey, version);
  }

  @override
  Future<String?> getSeedVersion() async {
    return _cache.read<String>(AreaCacheContract.seedVersionKey);
  }
}
