import '../../../core/cache/cache_store.dart';
import '../../../core/offline/local_cache_contract.dart';

class LocalCacheService implements LocalCacheContract {
  LocalCacheService(this._store);

  final CacheStore _store;

  static String _entryKey(String key) => 'local_cache:$key';

  @override
  Future<void> write(
    String key,
    Map<String, dynamic> payload,
    Duration ttl,
  ) async {
    await _store.put(_entryKey(key), {
      'payload': payload,
      'expiresAt': DateTime.now().add(ttl).millisecondsSinceEpoch,
    });
  }

  @override
  Future<Map<String, dynamic>?> read(String key) async {
    final entry = _store.read<Map<dynamic, dynamic>>(_entryKey(key));
    if (entry == null) return null;
    final expiresAt = entry['expiresAt'] as int?;
    if (expiresAt != null &&
        DateTime.now().millisecondsSinceEpoch > expiresAt) {
      await _store.delete(_entryKey(key));
      return null;
    }
    final payload = entry['payload'];
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    return null;
  }

  Future<void> delete(String key) => _store.delete(_entryKey(key));

  @override
  Future<void> evictExpired() async {
    // Minimal: entries expire on read.
  }

  @override
  Future<void> evictLru({
    required Set<String> protectedKeys,
    required int quotaBytes,
  }) async {
    // Quota enforcement deferred.
  }
}
