import 'package:sentry_flutter/sentry_flutter.dart';

import 'crash_reporter.dart';
import 'crash_reporting_context.dart';
import 'crash_report_throttle.dart';
import 'log_redactor.dart';
import 'sentry_bootstrap.dart';

/// Sentry adapter for [CrashReporter].
final class SentryCrashReporter implements CrashReporter {
  SentryCrashReporter({CrashReportThrottle? throttle})
    : _throttle = throttle ?? CrashReportThrottle();

  final CrashReportThrottle _throttle;
  String? _userId;

  @override
  void log(String message) {
    if (!SentryBootstrap.isInitialized) return;
    Sentry.addBreadcrumb(Breadcrumb(message: LogRedactor.redact(message)));
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
    Map<String, Object?>? context,
  }) async {
    if (!SentryBootstrap.isInitialized) return;

    final throttleKey =
        '${error.runtimeType}:${fatal ? 'fatal' : 'non_fatal'}:${reason ?? ''}';
    if (!_throttle.allow(throttleKey)) return;

    final merged = {...CrashReportingContext.snapshot(), ...?context};

    await Sentry.captureException(
      error,
      stackTrace: stack ?? StackTrace.current,
      withScope: (scope) {
        scope.setTag('fatal', fatal.toString());
        if (reason != null && reason.isNotEmpty) {
          scope.setTag('reason', LogRedactor.redact(reason));
        }
        for (final entry in merged.entries) {
          scope.setTag('ctx_${entry.key}', entry.value.toString());
        }
        if (_userId != null && _userId!.isNotEmpty) {
          scope.setUser(SentryUser(id: _userId));
        }
      },
    );
  }

  @override
  void setCustomKey(String key, Object value) {
    if (!SentryBootstrap.isInitialized) return;
    Sentry.configureScope((scope) {
      scope.setTag(key, value.toString());
    });
  }

  @override
  void setUserId(String? userId) {
    _userId = userId;
    if (!SentryBootstrap.isInitialized) return;
    Sentry.configureScope((scope) {
      scope.setUser(userId == null ? null : SentryUser(id: userId));
    });
  }
}
