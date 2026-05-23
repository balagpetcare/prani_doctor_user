import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_api_paths.dart';
import '../../features/auth/data/auth_dto.dart';
import '../auth/jwt_utils.dart';
import '../error/app_exception.dart';
import '../network/dio_helpers.dart';
import 'session_controller.dart';

const _hardAuthFailureCodes = {
  'TOKEN_INVALID',
  'UNAUTHORIZED',
  'UNAUTHORIZED_BEARER_REQUIRED',
};

/// Coordinates token refresh, request queuing, and session invalidation.
class SessionManager {
  SessionManager(this._session);

  final SessionController _session;

  Future<bool>? _refreshInFlight;
  int _refreshWaiters = 0;

  void _log(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[$tag] $message');
    }
  }

  bool _isHardAuthFailure(Object error) {
    if (error is AppException) {
      final code = error.code;
      return code != null && _hardAuthFailureCodes.contains(code);
    }
    return false;
  }

  bool _isTransientFailure(Object error) {
    if (error is DioException) {
      final type = error.type;
      return type == DioExceptionType.connectionTimeout ||
          type == DioExceptionType.receiveTimeout ||
          type == DioExceptionType.sendTimeout ||
          type == DioExceptionType.connectionError;
    }
    if (error is AppException) {
      final code = error.code;
      return code == '503' || code == '502' || code == '504';
    }
    return false;
  }

  /// Waits while another refresh is in progress (queues concurrent callers).
  Future<bool> refreshAccessToken({
    required Dio dio,
    int maxAttempts = 2,
  }) async {
    if (_refreshInFlight != null) {
      _refreshWaiters++;
      _log('REFRESH', 'queued (waiters=$_refreshWaiters)');
      try {
        return await _refreshInFlight!;
      } finally {
        _refreshWaiters--;
      }
    }

    final completer = Completer<bool>();
    _refreshInFlight = completer.future;
    _log('REFRESH', 'started');

    try {
      final result = await _performRefresh(dio: dio, maxAttempts: maxAttempts);
      completer.complete(result);
      return result;
    } catch (error, stack) {
      completer.completeError(error, stack);
      rethrow;
    } finally {
      _refreshInFlight = null;
      _log('REFRESH', 'finished (waiters=$_refreshWaiters)');
    }
  }

  Future<bool> _performRefresh({
    required Dio dio,
    required int maxAttempts,
  }) async {
    final refreshToken = await _session.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      _log('TOKEN', 'no stored refresh token');
      return false;
    }

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
        _log('REFRESH', 'retry attempt ${attempt + 1}/$maxAttempts');
      }

      // Re-read so rotation from a prior attempt is always used.
      final currentRefresh = await _session.readRefreshToken();
      if (currentRefresh == null || currentRefresh.isEmpty) {
        _log('TOKEN', 'refresh token cleared before attempt ${attempt + 1}');
        return false;
      }

      try {
        _log('REFRESH', 'POST ${AuthApiPaths.refresh}');
        final data = await postJson(dio, AuthApiPaths.refresh, {
          'refreshToken': currentRefresh,
        });
        final tokens = AuthTokensDto.fromJson(data);
        if (tokens.refreshToken == null || tokens.refreshToken!.isEmpty) {
          _log('TOKEN', 'backend returned access only — keeping prior refresh');
        }
        await _session.applyAuthTokens(tokens);
        _log('TOKEN', 'tokens applied from backend refresh');
        return true;
      } catch (error) {
        _log('REFRESH', 'failed: $error');
        if (_isHardAuthFailure(error)) {
          _log('SESSION', 'hard auth failure on refresh');
          return false;
        }
        if (!_isTransientFailure(error)) {
          return false;
        }
      }
    }

    _log('REFRESH', 'exhausted attempts');
    return false;
  }

  /// Proactive refresh when access JWT is expired but refresh token exists.
  Future<bool> ensureValidAccessToken({required Dio dio}) async {
    final access = await _session.readAccessToken();
    if (access != null &&
        access.isNotEmpty &&
        JwtUtils.isValidAccessToken(access) &&
        !JwtUtils.isExpired(access)) {
      return true;
    }
    _log('SESSION', 'access missing or expired — refreshing');
    return refreshAccessToken(dio: dio);
  }

  /// Recover from a protected API 401: refresh once, never sign out here.
  Future<bool> recoverFromUnauthorized({required Dio dio}) async {
    _log('AUTH', '401 on protected route — attempting refresh');
    return refreshAccessToken(dio: dio);
  }

  /// Sign out only after refresh + retry path failed with a hard auth error.
  Future<void> invalidateSession({required String reason}) async {
    _log('SESSION', 'invalidate: $reason');
    await _session.signOut();
  }
}

final sessionManagerProvider = Provider<SessionManager>((ref) {
  return SessionManager(ref.watch(sessionControllerProvider.notifier));
});
