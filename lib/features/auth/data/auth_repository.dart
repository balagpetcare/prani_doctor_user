import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_result.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_helpers.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/session/session_controller.dart';
import 'auth_api_paths.dart';
import 'auth_dto.dart';

/// Coordinates mobile OTP/password auth.
class AuthRepository {
  AuthRepository(this._dio, this._sessionController);

  final Dio _dio;
  final SessionController _sessionController;

  Future<ApiResult<OtpRequestResultDto>> requestOtp(String phone) async {
    try {
      final data = await postJson(_dio, AuthApiPaths.otpRequest, {'phone': phone.trim()});
      return ApiResult.success(OtpRequestResultDto.fromJson(data));
    } on AppException catch (e) {
      return ApiResult.failure(e);
    } catch (e) {
      return ApiResult.failure(AppException(message: 'OTP request failed', cause: e));
    }
  }

  Future<ApiResult<AuthTokensDto>> verifyOtp({
    required String phone,
    required String code,
    String? pushToken,
  }) async {
    try {
      final deviceKey = await _sessionController.deviceKey();
      final data = await postJson(_dio, AuthApiPaths.otpVerify, {
        'phone': phone.trim(),
        'code': code.trim(),
        'deviceKey': deviceKey,
        'platform': 'android',
        if (pushToken != null) 'pushToken': pushToken,
      });
      final tokens = AuthTokensDto.fromJson(data);
      await _sessionController.applyAuthTokens(tokens, phone: phone.trim());
      return ApiResult.success(tokens);
    } on AppException catch (e) {
      return ApiResult.failure(e);
    } catch (e) {
      return ApiResult.failure(AppException(message: 'OTP verification failed', cause: e));
    }
  }

  Future<ApiResult<AuthTokensDto>> loginWithPassword({
    required String identifier,
    required String password,
    String? pushToken,
  }) async {
    try {
      final deviceKey = await _sessionController.deviceKey();
      final data = await postJson(_dio, AuthApiPaths.login, {
        'identifier': identifier.trim(),
        'password': password,
        'deviceKey': deviceKey,
        'platform': 'android',
        if (pushToken != null) 'pushToken': pushToken,
      });
      final tokens = AuthTokensDto.fromJson(data);
      await _sessionController.applyAuthTokens(tokens);
      return ApiResult.success(tokens);
    } on AppException catch (e) {
      return ApiResult.failure(e);
    } catch (e) {
      return ApiResult.failure(AppException(message: 'Login failed', cause: e));
    }
  }

  Future<ApiResult<AuthTokensDto>> register({
    required String name,
    required String mobile,
    required String password,
    String? email,
  }) async {
    try {
      final data = await postJson(_dio, AuthApiPaths.register, {
        'name': name.trim(),
        'mobile': mobile.trim(),
        'password': password,
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      });
      final tokens = AuthTokensDto.fromJson(data);
      await _sessionController.applyAuthTokens(tokens, phone: mobile.trim());
      return ApiResult.success(tokens);
    } on AppException catch (e) {
      return ApiResult.failure(e);
    } catch (e) {
      return ApiResult.failure(AppException(message: 'Registration failed', cause: e));
    }
  }

  /// Returns `true` when tokens were rotated successfully.
  Future<bool> refreshSession() async {
    final refreshToken = await _sessionController.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final data = await postJson(_dio, AuthApiPaths.refresh, {
        'refreshToken': refreshToken,
      });
      final tokens = AuthTokensDto.fromJson(data);
      await _sessionController.applyAuthTokens(tokens);
      return true;
    } catch (_) {
      await _sessionController.signOut();
      return false;
    }
  }

  Future<void> signOut() => _sessionController.signOut();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final session = ref.watch(sessionControllerProvider.notifier);
  return AuthRepository(dio, session);
});
