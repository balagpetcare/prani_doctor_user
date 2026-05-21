import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../auth/jwt_utils.dart';
import '../../features/auth/data/auth_dto.dart';
import 'session_state.dart';

/// Holds authentication snapshot and secure token persistence.
class SessionController extends StateNotifier<SessionState> {
  SessionController(this._secureStorage) : super(const SessionState());

  final FlutterSecureStorage _secureStorage;

  static const _accessTokenKey = 'auth.accessToken';
  static const _refreshTokenKey = 'auth.refreshToken';
  static const _userIdKey = 'auth.userId';
  static const _displayNameKey = 'auth.displayName';
  static const _phoneKey = 'auth.phone';
  static const _deviceKeyKey = 'auth.deviceKey';

  Future<String?> readAccessToken() => _secureStorage.read(key: _accessTokenKey);

  Future<String?> readRefreshToken() => _secureStorage.read(key: _refreshTokenKey);

  Future<bool> isAccessTokenExpired() async {
    final token = await readAccessToken();
    if (token == null || token.isEmpty) return true;
    return JwtUtils.isExpired(token);
  }

  Future<String> deviceKey() async {
    final existing = await _secureStorage.read(key: _deviceKeyKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = _generateDeviceKey();
    await _secureStorage.write(key: _deviceKeyKey, value: generated);
    return generated;
  }

  Future<void> restoreFromStorage() async {
    final token = await readAccessToken();
    if (token == null || token.isEmpty) {
      state = const SessionState();
      return;
    }

    final userId =
        await _secureStorage.read(key: _userIdKey) ?? JwtUtils.subject(token);
    final displayName = await _secureStorage.read(key: _displayNameKey);
    final phone = await _secureStorage.read(key: _phoneKey);

    state = SessionState(
      isAuthenticated: !JwtUtils.isExpired(token),
      userId: userId,
      displayName: displayName,
      phone: phone,
    );
  }

  Future<void> applyAuthTokens(AuthTokensDto tokens, {String? phone}) async {
    final user = tokens.user;
    final userId = user?.id ?? JwtUtils.subject(tokens.accessToken);
    final displayName = user?.name;
    final resolvedPhone = phone ?? user?.mobile;

    await _secureStorage.write(key: _accessTokenKey, value: tokens.accessToken);
    if (tokens.refreshToken != null) {
      await _secureStorage.write(
        key: _refreshTokenKey,
        value: tokens.refreshToken,
      );
    }
    if (userId != null) {
      await _secureStorage.write(key: _userIdKey, value: userId);
    }
    if (displayName != null) {
      await _secureStorage.write(key: _displayNameKey, value: displayName);
    }
    if (resolvedPhone != null) {
      await _secureStorage.write(key: _phoneKey, value: resolvedPhone);
    }

    state = SessionState(
      isAuthenticated: true,
      userId: userId,
      displayName: displayName,
      phone: resolvedPhone,
    );
  }

  Future<void> signInDevPlaceholder() async {
    if (!kDebugMode) return;
    await applyAuthTokens(
      const AuthTokensDto(
        accessToken: 'dev-token',
        expiresInSeconds: 3600,
        user: AuthUserDto(
          id: 'dev-user',
          name: 'Development User',
          mobile: '+8801000000000',
        ),
      ),
      phone: '+8801000000000',
    );
  }

  Future<void> signOut() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _userIdKey);
    await _secureStorage.delete(key: _displayNameKey);
    await _secureStorage.delete(key: _phoneKey);
    state = const SessionState();
  }

  Future<void> setSession({
    required String userId,
    String? displayName,
    required String accessToken,
    String? refreshToken,
    String? phone,
  }) async {
    await applyAuthTokens(
      AuthTokensDto(
        accessToken: accessToken,
        expiresInSeconds: 3600,
        refreshToken: refreshToken,
        user: AuthUserDto(
          id: userId,
          name: displayName ?? '',
          mobile: phone ?? '',
        ),
      ),
      phone: phone,
    );
  }

  String _generateDeviceKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
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
