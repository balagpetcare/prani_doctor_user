import 'package:dio/dio.dart';

import '../error/app_exception.dart';

const offlineQueuedCode = 'OFFLINE_QUEUED';

bool isTransientNetworkError(AppException error) {
  if (error.code == offlineQueuedCode) return false;
  final cause = error.cause;
  if (cause is DioException) {
    switch (cause.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final status = cause.response?.statusCode;
        return status == 502 || status == 503 || status == 504;
      default:
        return false;
    }
  }
  if (error.code == null && error.message.toLowerCase().contains('network')) {
    return true;
  }
  return false;
}

Duration offlineRetryDelay(int attemptCount) {
  const baseMs = 30000;
  const maxMs = 3600000;
  final delayMs = baseMs * (1 << (attemptCount - 1).clamp(0, 10));
  return Duration(milliseconds: delayMs.clamp(baseMs, maxMs));
}

const offlineMaxAttempts = 5;
