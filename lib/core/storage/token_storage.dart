import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Isolated secure persistence for auth tokens and identity metadata.
///
/// Encapsulates the secure-storage key namespace and read/write/delete so the
/// session layer no longer touches `FlutterSecureStorage` directly (service
/// isolation). Key strings are unchanged from the previous inline
/// implementation to preserve on-device data and test compatibility.
class TokenStorage {
  TokenStorage(this._secureStorage, {Map<String, String>? testStore})
    : _testStore = testStore;

  final FlutterSecureStorage _secureStorage;
  final Map<String, String>? _testStore;

  static const accessTokenKey = 'auth.accessToken';
  static const refreshTokenKey = 'auth.refreshToken';
  static const userIdKey = 'auth.userId';
  static const displayNameKey = 'auth.displayName';
  static const phoneKey = 'auth.phone';
  static const deviceKeyKey = 'auth.deviceKey';

  Future<String?> read(String key) async {
    if (_testStore != null) return _testStore[key];
    return _secureStorage.read(key: key);
  }

  Future<void> write(String key, String value) async {
    if (_testStore != null) {
      _testStore[key] = value;
      return;
    }
    await _secureStorage.write(key: key, value: value);
  }

  Future<void> delete(String key) async {
    if (_testStore != null) {
      _testStore.remove(key);
      return;
    }
    await _secureStorage.delete(key: key);
  }

  Future<String?> readAccessToken() => read(accessTokenKey);

  Future<String?> readRefreshToken() => read(refreshTokenKey);

  /// Clears all auth tokens + identity metadata (used on sign-out / invalidation).
  Future<void> clearTokens() async {
    await delete(accessTokenKey);
    await delete(refreshTokenKey);
    await delete(userIdKey);
    await delete(displayNameKey);
    await delete(phoneKey);
  }
}
