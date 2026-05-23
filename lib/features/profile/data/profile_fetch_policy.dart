import '../../../core/error/app_exception.dart';

/// Profile API fetch limits (cache → API → refresh handled in repository/provider).
abstract final class ProfileFetchPolicy {
  static const maxAttempts = 2;
  static const requestTimeout = Duration(seconds: 15);

  static bool isRetryable(AppException error) {
    final code = error.code;
    if (code == null) return true;
    const noRetry = {
      '401',
      '403',
      '404',
      '405',
      '422',
      'UNAUTHORIZED',
      'FORBIDDEN',
      'NOT_FOUND',
      'METHOD_NOT_ALLOWED',
      'VALIDATION_ERROR',
    };
    return !noRetry.contains(code);
  }
}
