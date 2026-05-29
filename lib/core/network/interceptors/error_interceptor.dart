import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auto_refresh_guard.dart';

/// Tracks server reachability for the offline/“server down” banner:
/// records success on any `< 500` response and failure on transient errors
/// (timeouts, connection errors, `>= 500`). Always forwards the error/response.
class ErrorInterceptor extends Interceptor {
  ErrorInterceptor(this._ref);

  final Ref _ref;

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final status = response.statusCode;
    if (status != null && status < 500) {
      _ref.read(autoRefreshGuardProvider.notifier).recordApiSuccess();
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    final isTransient =
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError ||
        (status != null && status >= 500);
    if (isTransient) {
      _ref.read(autoRefreshGuardProvider.notifier).recordApiFailure();
    }
    handler.next(err);
  }
}
