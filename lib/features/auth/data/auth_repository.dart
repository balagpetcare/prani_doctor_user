import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/error/api_result.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_helpers.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/offline/local_cache_contract.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/session/session_manager.dart';
import '../../offline/data/local_cache_service.dart';
import '../../offline/offline_providers.dart';
import 'auth_api_paths.dart';
import 'auth_dto.dart';
import 'auth_platform.dart';
import 'auth_preferences.dart';
import 'auth_repository_contract.dart';

/// Production mobile auth repository with offline-friendly OTP cache.
class AuthRepository implements AuthRepositoryContract {
  AuthRepository(
    this._dio,
    this._sessionController,
    this._sessionManager,
    this._cache,
    this._preferences,
  );

  final Dio _dio;
  final SessionController _sessionController;
  final SessionManager _sessionManager;
  final LocalCacheService _cache;
  final AuthPreferences _preferences;

  static String _otpCacheKey(String phone) =>
      '${LocalCacheContract.authOtpPendingPrefix}${phone.trim()}';

  Future<Map<String, dynamic>> _devicePayload({String? pushToken}) async {
    final deviceKey = await _sessionController.deviceKey();
    final info = await PackageInfo.fromPlatform();
    return {
      'deviceKey': deviceKey,
      'platform': AuthPlatform.current(),
      'appVersion': info.version,
      'pushToken': ?pushToken,
    };
  }

  Future<void> _persistSession(
    AuthTokensDto tokens, {
    String? phone,
    required bool rememberSession,
  }) async {
    await _preferences.setRememberSession(rememberSession);
    if (phone != null) {
      await _preferences.setLastPhone(phone);
    }
    await _sessionController.applyAuthTokens(tokens, phone: phone);
    await _cache.write(LocalCacheContract.authSnapshotKey, {
      'userId': tokens.user?.id,
      'displayName': tokens.user?.name,
      'phone': phone ?? tokens.user?.mobile,
      'rememberSession': rememberSession,
    }, LocalCacheContract.authTtl);
  }

  @override
  Future<String?> readCachedPhone() => _preferences.lastPhone();

  @override
  Future<OtpRequestResultDto?> readCachedOtpRequest(String phone) async {
    final cached = await _cache.read(_otpCacheKey(phone));
    if (cached == null) return null;
    return OtpRequestResultDto.fromJson(cached);
  }

  @override
  Future<ApiResult<OtpRequestResultDto>> requestOtp(String phone) async {
    final trimmed = phone.trim();
    try {
      final data = await postJson(_dio, AuthApiPaths.otpRequest, {
        'phone': trimmed,
      });
      final result = OtpRequestResultDto.fromJson(data);
      await _cache.write(_otpCacheKey(trimmed), {
        ...data,
        'requestedAt': DateTime.now().toIso8601String(),
      }, Duration(seconds: result.otpTtlSeconds));
      await _preferences.setLastPhone(trimmed);
      return ApiResult.success(result);
    } on AppException catch (e) {
      final cached = await readCachedOtpRequest(trimmed);
      if (cached != null && e.code != 'RESEND_COOLDOWN') {
        return ApiResult.success(cached);
      }
      return ApiResult.failure(e);
    } catch (e) {
      return ApiResult.failure(
        AppException(message: 'OTP request failed', cause: e),
      );
    }
  }

  @override
  Future<ApiResult<AuthTokensDto>> verifyOtp({
    required String phone,
    required String code,
    String? pushToken,
    bool rememberSession = true,
  }) async {
    try {
      final payload = {
        'phone': phone.trim(),
        'code': code.trim(),
        ...await _devicePayload(pushToken: pushToken),
      };
      final data = await postJson(_dio, AuthApiPaths.otpVerify, payload);
      final tokens = AuthTokensDto.fromJson(data);
      await _persistSession(
        tokens,
        phone: phone.trim(),
        rememberSession: rememberSession,
      );
      if (kDebugMode) {
        debugPrint('[AUTH] OTP verify succeeded');
      }
      await _cache.delete(_otpCacheKey(phone));
      return ApiResult.success(tokens);
    } on AppException catch (e) {
      return ApiResult.failure(e);
    } catch (e) {
      return ApiResult.failure(
        AppException(message: 'OTP verification failed', cause: e),
      );
    }
  }

  @override
  Future<ApiResult<AuthTokensDto>> loginWithPassword({
    required String identifier,
    required String password,
    String? pushToken,
    bool rememberSession = true,
  }) async {
    try {
      final payload = {
        'identifier': identifier.trim(),
        'password': password,
        ...await _devicePayload(pushToken: pushToken),
      };
      final data = await postJson(_dio, AuthApiPaths.login, payload);
      final tokens = AuthTokensDto.fromJson(data);
      await _persistSession(tokens, rememberSession: rememberSession);
      return ApiResult.success(tokens);
    } on AppException catch (e) {
      return ApiResult.failure(e);
    } catch (e) {
      return ApiResult.failure(AppException(message: 'Login failed', cause: e));
    }
  }

  @override
  Future<ApiResult<AuthTokensDto>> register({
    required String name,
    required String mobile,
    required String password,
    String? email,
    String? pushToken,
    bool rememberSession = true,
  }) async {
    try {
      final data = await postJson(_dio, AuthApiPaths.register, {
        'name': name.trim(),
        'mobile': mobile.trim(),
        'password': password,
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      });
      final tokens = AuthTokensDto.fromJson(data);
      await _persistSession(
        tokens,
        phone: mobile.trim(),
        rememberSession: rememberSession,
      );
      return ApiResult.success(tokens);
    } on AppException catch (e) {
      return ApiResult.failure(e);
    } catch (e) {
      return ApiResult.failure(
        AppException(message: 'Registration failed', cause: e),
      );
    }
  }

  @override
  Future<bool> refreshSession() {
    return _sessionManager.refreshAccessToken(dio: _dio);
  }

  @override
  Future<void> signOut({bool clearPreferences = false}) async {
    await _revokeServerSession();
    await _sessionController.signOut();
    await _clearAuthCaches();
    if (clearPreferences) {
      await _preferences.setRememberSession(true);
    }
  }

  Future<void> _revokeServerSession() async {
    final token = await _sessionController.readAccessToken();
    if (token == null || token.isEmpty) return;

    try {
      await postJson(_dio, AuthApiPaths.logout, {});
    } catch (_) {
      // Best-effort server revoke; local cleanup always proceeds.
    }
  }

  Future<void> _clearAuthCaches() async {
    await _cache.delete(LocalCacheContract.authSnapshotKey);
    await _cache.delete(LocalCacheContract.profileKey);
    await _cache.delete(LocalCacheContract.profileAddressKey);
    await _cache.delete(LocalCacheContract.dashboardKey);
    await _cache.delete(LocalCacheContract.farmsListKey);
    await _cache.delete(LocalCacheContract.farmDraftKey);
    await _cache.delete(LocalCacheContract.activeFarmIdKey);
    await _cache.delete(LocalCacheContract.animalsListKey);
    await _cache.delete(LocalCacheContract.animalDraftKey);
    await _cache.write('profile_location_draft', {}, Duration.zero);

    final lastPhone = await _preferences.lastPhone();
    if (lastPhone != null && lastPhone.isNotEmpty) {
      await _cache.delete(_otpCacheKey(lastPhone));
    }
  }
}

final authRepositoryProvider = Provider<AuthRepositoryContract>((ref) {
  return AuthRepository(
    ref.watch(dioProvider),
    ref.watch(sessionControllerProvider.notifier),
    ref.watch(sessionManagerProvider),
    ref.watch(localCacheServiceProvider),
    ref.watch(authPreferencesProvider),
  );
});
