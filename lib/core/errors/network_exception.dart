import 'package:dio/dio.dart';

import '../error/app_exception.dart';
import '../error/http_error_mapper.dart';
import '../offline/network_errors.dart' show offlineQueuedCode;

/// Typed classification of API/network failures for UI and retry decisions.
enum NetworkErrorType {
  noConnection,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  validation,
  conflict,
  server,
  cancelled,
  offlineQueued,
  badResponse,
  unknown,
}

/// Maps a [DioException] to a [NetworkErrorType].
NetworkErrorType classifyDioError(DioException error) {
  if (CancelToken.isCancel(error)) return NetworkErrorType.cancelled;
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return NetworkErrorType.timeout;
    case DioExceptionType.connectionError:
      return NetworkErrorType.noConnection;
    case DioExceptionType.cancel:
      return NetworkErrorType.cancelled;
    case DioExceptionType.badCertificate:
      return NetworkErrorType.badResponse;
    case DioExceptionType.badResponse:
      return _fromStatus(error.response?.statusCode);
    case DioExceptionType.unknown:
      return NetworkErrorType.unknown;
  }
}

NetworkErrorType _fromStatus(int? status) {
  if (status == null) return NetworkErrorType.unknown;
  if (status >= 500) return NetworkErrorType.server;
  switch (status) {
    case 401:
      return NetworkErrorType.unauthorized;
    case 403:
      return NetworkErrorType.forbidden;
    case 404:
      return NetworkErrorType.notFound;
    case 409:
      return NetworkErrorType.conflict;
    case 422:
      return NetworkErrorType.validation;
    default:
      return NetworkErrorType.badResponse;
  }
}

NetworkErrorType _fromCode(String? code) {
  switch (code) {
    case 'UNAUTHORIZED':
    case 'UNAUTHORIZED_BEARER_REQUIRED':
    case 'TOKEN_INVALID':
    case '401':
      return NetworkErrorType.unauthorized;
    case 'FORBIDDEN':
    case 'FORBIDDEN_CUSTOMER_REQUIRED':
    case '403':
      return NetworkErrorType.forbidden;
    case 'NOT_FOUND':
    case '404':
      return NetworkErrorType.notFound;
    case '409':
      return NetworkErrorType.conflict;
    case '422':
      return NetworkErrorType.validation;
    case '500':
    case '502':
    case '503':
    case '504':
      return NetworkErrorType.server;
    default:
      return NetworkErrorType.unknown;
  }
}

/// Typed accessors on the app's canonical [AppException].
extension AppExceptionType on AppException {
  NetworkErrorType get networkType {
    if (code == offlineQueuedCode) return NetworkErrorType.offlineQueued;
    final c = cause;
    if (c is DioException) return classifyDioError(c);
    return _fromCode(code);
  }

  bool get isOffline =>
      networkType == NetworkErrorType.noConnection ||
      networkType == NetworkErrorType.timeout;

  bool get isUnauthorized => networkType == NetworkErrorType.unauthorized;

  bool get isQueuedOffline => networkType == NetworkErrorType.offlineQueued;
}

/// User-facing message for any API failure, safe for arbitrary [Object] errors.
String apiFailureMessage(Object error) {
  if (error is AppException) return error.message;
  if (error is DioException) return HttpErrorMapper.fromDio(error).message;
  return HttpErrorMapper.genericSubtitle;
}
