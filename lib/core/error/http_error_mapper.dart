import 'package:dio/dio.dart';

import '../logging/app_logger.dart';
import 'app_exception.dart';

/// Maps HTTP status / [AppException] codes to user-facing copy (no raw Dio text).
abstract final class HttpErrorMapper {
  static const profileLoadTitle = 'Unable to load profile';
  static const settingsLoadTitle = 'Unable to load settings';
  static const genericSubtitle = 'Please try again';

  static AppException fromStatus({
    required int? statusCode,
    String? serverMessage,
    String? serverCode,
    Object? cause,
  }) {
    final code = serverCode ?? statusCode?.toString();
    final message = switch (statusCode) {
      401 => 'Session expired. Please sign in again.',
      403 => 'Permission denied.',
      404 => 'Profile unavailable.',
      405 => 'Service unavailable. Try again later.',
      422 => serverMessage ?? 'Some fields are invalid.',
      500 || 502 || 503 || 504 => 'Server problem. Please try again.',
      _ => serverMessage ?? 'Network error. Please try again.',
    };
    return AppException(message: message, code: code, cause: cause);
  }

  static AppException fromDio(DioException error) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final err = data['error'];
      if (err is Map<String, dynamic>) {
        return fromStatus(
          statusCode: status,
          serverMessage: err['message'] as String?,
          serverCode: err['code'] as String?,
          cause: error,
        );
      }
    }
    return fromStatus(
      statusCode: status,
      serverMessage: error.message,
      cause: error,
    );
  }

  static String profileErrorTitle(Object error) {
    final code = _codeOf(error);
    return switch (code) {
      '401' ||
      'UNAUTHORIZED' ||
      'UNAUTHORIZED_BEARER_REQUIRED' => 'Session expired',
      '403' ||
      'FORBIDDEN' ||
      'FORBIDDEN_CUSTOMER_REQUIRED' => 'Permission denied',
      '404' || 'NOT_FOUND' => 'Profile unavailable',
      '405' || 'METHOD_NOT_ALLOWED' => 'Service unavailable',
      '500' || '502' || '503' || '504' => 'Server problem',
      _ => profileLoadTitle,
    };
  }

  static String settingsErrorTitle(Object error) {
    final code = _codeOf(error);
    return switch (code) {
      '401' || 'UNAUTHORIZED' => 'Session expired',
      '403' || 'FORBIDDEN' => 'Permission denied',
      '404' || 'NOT_FOUND' => 'Settings unavailable',
      '405' || 'METHOD_NOT_ALLOWED' => 'Service unavailable',
      '500' || '502' || '503' || '504' => 'Server problem',
      _ => settingsLoadTitle,
    };
  }

  static String profileErrorMessage(Object error) => _messageOf(error);

  static String settingsErrorMessage(Object error) => _messageOf(error);

  static String? _codeOf(Object error) {
    if (error is AppException) return error.code;
    if (error is DioException) return error.response?.statusCode?.toString();
    return null;
  }

  static String _messageOf(Object error) {
    if (error is AppException) return error.message;
    if (error is DioException) return fromDio(error).message;
    return genericSubtitle;
  }

  static void logDeveloper(Object error, {String tag = 'API'}) {
    AppLog.debug('developer: $error', tag: tag);
    if (error is AppException && error.cause != null) {
      AppLog.debug('cause: ${error.cause}', tag: tag);
    }
  }
}
