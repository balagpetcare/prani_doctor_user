import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'session_state.dart';

/// Holds authentication snapshot. Replace placeholder sign-in with real auth flows.
class SessionController extends StateNotifier<SessionState> {
  SessionController(this._secureStorage) : super(const SessionState());

  final FlutterSecureStorage _secureStorage;

  static const _accessTokenKey = 'auth.accessToken';

  Future<void> restoreFromStorage() async {
    final token = await _secureStorage.read(key: _accessTokenKey);
    if (token != null && token.isNotEmpty) {
      state = state.copyWith(isAuthenticated: true);
    }
  }

  Future<void> signInDevPlaceholder() async {
    await _secureStorage.write(key: _accessTokenKey, value: 'dev-token');
    state = state.copyWith(
      isAuthenticated: true,
      userId: 'dev-user',
      displayName: 'Development User',
    );
  }

  Future<void> signOut() async {
    await _secureStorage.delete(key: _accessTokenKey);
    state = const SessionState();
  }

  Future<void> setSession({
    required String userId,
    String? displayName,
    required String accessToken,
  }) async {
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    state = state.copyWith(
      isAuthenticated: true,
      userId: userId,
      displayName: displayName,
    );
  }
}

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
});

final sessionControllerProvider =
    StateNotifierProvider<SessionController, SessionState>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return SessionController(storage);
});
