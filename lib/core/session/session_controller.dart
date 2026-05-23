import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../auth/jwt_utils.dart';
import '../../features/auth/data/auth_dto.dart';
import 'session_state.dart';

/// Holds authentication snapshot and secure token persistence.
class SessionController extends StateNotifier<SessionState> {
  SessionController(
    this._secureStorage, {
    @visibleForTesting Map<String, String>? testStore,
  }) : _testStore = testStore,
       super(const SessionState());

  final FlutterSecureStorage _secureStorage;
  final Map<String, String>? _testStore;

  static const _accessTokenKey = 'auth.accessToken';
  static const _refreshTokenKey = 'auth.refreshToken';
  static const _userIdKey = 'auth.userId';
  static const _displayNameKey = 'auth.displayName';
  static const _phoneKey = 'auth.phone';
  static const _deviceKeyKey = 'auth.deviceKey';

  String? _memoryAccessToken;

  Future<String?> _readKey(String key) async {
    if (_testStore != null) return _testStore[key];
    return _secureStorage.read(key: key);
  }

  Future<void> _writeKey(String key, String value) async {
    if (_testStore != null) {
      _testStore[key] = value;
      return;
    }
    await _secureStorage.write(key: key, value: value);
  }

  Future<void> _deleteKey(String key) async {
    if (_testStore != null) {
      _testStore.remove(key);
      return;
    }
    await _secureStorage.delete(key: key);
  }

  Future<String?> readAccessToken() async {
    if (_memoryAccessToken != null && _memoryAccessToken!.isNotEmpty) {
      return _memoryAccessToken;
    }
    final stored = await _readKey(_accessTokenKey);
    if (stored != null && stored.isNotEmpty) {
      _memoryAccessToken = stored;
    }
    return stored;
  }

  Future<String?> readRefreshToken() => _readKey(_refreshTokenKey);

  Future<bool> isAccessTokenExpired() async {
    final token = await readAccessToken();
    if (token == null || token.isEmpty) return true;
    return JwtUtils.isExpired(token);
  }

  Future<String> deviceKey() async {
    final existing = await _readKey(_deviceKeyKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = _generateDeviceKey();
    await _writeKey(_deviceKeyKey, generated);
    return generated;
  }

  Future<void> restoreFromStorage() async {
    final token = await _readKey(_accessTokenKey);
    _memoryAccessToken = token;

    if (token == null ||
        token.isEmpty ||
        !JwtUtils.isValidAccessToken(token) ||
        JwtUtils.isExpired(token)) {
      final refresh = await _readKey(_refreshTokenKey);
      if (refresh != null && refresh.isNotEmpty) {
        // Keep backend-issued refresh token for boot-time rotation.
        _memoryAccessToken = null;
        if (kDebugMode) {
          debugPrint(
            '[AUTH] access expired or missing — refresh token retained',
          );
        }
        state = const SessionState(sessionReady: true);
        return;
      }
      if (token != null && token.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('[AUTH] clearing invalid stored access token');
        }
        await _clearStoredTokens();
      }
      state = const SessionState(sessionReady: true);
      return;
    }

    final userId = await _readKey(_userIdKey) ?? JwtUtils.subject(token);
    final displayName = await _readKey(_displayNameKey);
    final phone = await _readKey(_phoneKey);

    state = SessionState(
      isAuthenticated: true,
      sessionReady: true,
      userId: userId,
      displayName: displayName,
      phone: phone,
    );
  }

  Future<void> applyAuthTokens(AuthTokensDto tokens, {String? phone}) async {
    if (kDebugMode) {
      debugPrint(
        '[TOKEN] applyAuthTokens (hasRefresh=${tokens.refreshToken?.isNotEmpty == true})',
      );
    }
    if (!JwtUtils.isValidAccessToken(tokens.accessToken)) {
      throw StateError('Invalid access token from auth response');
    }

    final user = tokens.user;
    final userId = user?.id ?? JwtUtils.subject(tokens.accessToken);
    final displayName = user?.name;
    final resolvedPhone = phone ?? user?.mobile;

    _memoryAccessToken = tokens.accessToken;
    await _writeKey(_accessTokenKey, tokens.accessToken);
    if (tokens.refreshToken != null && tokens.refreshToken!.isNotEmpty) {
      await _writeKey(_refreshTokenKey, tokens.refreshToken!);
    }
    if (userId != null) {
      await _writeKey(_userIdKey, userId);
    }
    if (displayName != null) {
      await _writeKey(_displayNameKey, displayName);
    }
    if (resolvedPhone != null) {
      await _writeKey(_phoneKey, resolvedPhone);
    }

    state = SessionState(
      isAuthenticated: true,
      sessionReady: true,
      userId: userId,
      displayName: displayName,
      phone: resolvedPhone,
    );
  }

  Future<void> signInDevPlaceholder() async {
    if (!kDebugMode) return;
  }

  Future<void> signOut() async {
    if (kDebugMode) {
      debugPrint('[SESSION] signOut');
    }
    await _clearStoredTokens();
    _memoryAccessToken = null;
    state = const SessionState(sessionReady: true);
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

  Future<void> _clearStoredTokens() async {
    await _deleteKey(_accessTokenKey);
    await _deleteKey(_refreshTokenKey);
    await _deleteKey(_userIdKey);
    await _deleteKey(_displayNameKey);
    await _deleteKey(_phoneKey);
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

/// True when boot/session restore finished and the user may call protected APIs.
final sessionReadyProvider = Provider<bool>((ref) {
  return ref.watch(sessionControllerProvider.select((s) => s.sessionReady));
});
