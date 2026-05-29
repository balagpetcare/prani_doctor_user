import 'package:dio/dio.dart';

import '../../errors/network_exception.dart';
import '../../logging/app_logger.dart';
import '../../logging/crash_report_throttle.dart';
import '../../logging/crash_reporting_context.dart';
import '../../logging/log_redactor.dart';

/// Reports unexpected network failures as **non-fatal** crash events.
///
/// Expected auth/validation/not-found responses are skipped. Reports are
/// throttled per method+path to avoid flooding backends during outages.
final class CrashReportingNetworkInterceptor extends Interceptor {
  CrashReportingNetworkInterceptor({CrashReportThrottle? throttle})
    : _throttle = throttle ?? CrashReportThrottle();

  static final CrashReportThrottle _sharedThrottle = CrashReportThrottle();

  final CrashReportThrottle _throttle;

  factory CrashReportingNetworkInterceptor.shared() {
    return CrashReportingNetworkInterceptor(throttle: _sharedThrottle);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_shouldReport(err)) {
      final path = err.requestOptions.path;
      final key = '${err.requestOptions.method}:$path';
      if (_throttle.allow(key)) {
        final type = classifyDioError(err);
        AppLog.error(
          'Network failure',
          tag: 'Network',
          error: err,
          stackTrace: err.stackTrace,
          fatal: false,
          data: {
            'category': CrashErrorCategory.networkUnexpected,
            'network_type': type.name,
            'status': err.response?.statusCode,
            'method': err.requestOptions.method,
            'path': LogRedactor.redactUri(path),
          },
        );
      }
    }
    handler.next(err);
  }

  bool _shouldReport(DioException err) {
    final type = classifyDioError(err);
    return switch (type) {
      NetworkErrorType.unauthorized ||
      NetworkErrorType.forbidden ||
      NetworkErrorType.notFound ||
      NetworkErrorType.validation ||
      NetworkErrorType.conflict ||
      NetworkErrorType.cancelled ||
      NetworkErrorType.offlineQueued => false,
      NetworkErrorType.noConnection ||
      NetworkErrorType.timeout ||
      NetworkErrorType.server ||
      NetworkErrorType.badResponse ||
      NetworkErrorType.unknown => true,
    };
  }
}
