import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/cache_store.dart';
import '../../../core/cache/cache_providers.dart';

/// Non-sensitive auth UX preferences (welcome seen, remember session).
class AuthPreferences {
  AuthPreferences(this._store);

  final CacheStore _store;

  static const _welcomeSeenKey = 'auth.welcomeSeen';
  static const _rememberSessionKey = 'auth.rememberSession';
  static const _lastPhoneKey = 'auth.lastPhone';

  Future<bool> isWelcomeSeen() async {
    return _store.read<bool>(_welcomeSeenKey) ?? false;
  }

  Future<void> setWelcomeSeen(bool value) => _store.put(_welcomeSeenKey, value);

  Future<bool> rememberSession() async {
    return _store.read<bool>(_rememberSessionKey) ?? true;
  }

  Future<void> setRememberSession(bool value) =>
      _store.put(_rememberSessionKey, value);

  Future<String?> lastPhone() async => _store.read<String>(_lastPhoneKey);

  Future<void> setLastPhone(String phone) =>
      _store.put(_lastPhoneKey, phone.trim());
}

final authPreferencesProvider = Provider<AuthPreferences>((ref) {
  return AuthPreferences(ref.watch(cacheStoreProvider));
});
