import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../logging/app_logger.dart';
import '../../logging/log_redactor.dart';

/// Debug-only request/error logging. [enabled] should be
/// `env.logNetwork` (which already implies `kDebugMode`).
///
/// Never logs Authorization headers or token values.
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor({required this.enabled});

  final bool enabled;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (enabled) {
      final ct = options.headers['Content-Type'];
      AppLog.debug(
        '→ ${options.method} ${LogRedactor.redactUri(options.uri.toString())}'
        '${options.data is FormData ? ' [multipart]' : ''}'
        '${ct != null ? ' ct=$ct' : ''}',
        tag: 'HTTP',
      );
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    if (status == 405 && kDebugMode) {
      AppLog.warn(
        '405 Method Not Allowed ${err.requestOptions.method} '
        '${err.requestOptions.path}',
        tag: 'HTTP',
      );
    }
    if (enabled) {
      AppLog.debug(
        '✗ ${err.requestOptions.method} '
        '${LogRedactor.redactUri(err.requestOptions.uri.toString())} '
        'status=$status',
        tag: 'HTTP',
      );
    }
    handler.next(err);
  }
}
