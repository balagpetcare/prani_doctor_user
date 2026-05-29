import 'dart:async';

import 'crash_reporter.dart';

/// Fan-out adapter — delegates to multiple [CrashReporter] backends without
/// blocking callers (each delegate runs via [unawaited]).
final class CompositeCrashReporter implements CrashReporter {
  CompositeCrashReporter(this._delegates);

  final List<CrashReporter> _delegates;

  @override
  void log(String message) {
    for (final delegate in _delegates) {
      delegate.log(message);
    }
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
    Map<String, Object?>? context,
  }) async {
    for (final delegate in _delegates) {
      unawaited(
        delegate.recordError(
          error,
          stack,
          fatal: fatal,
          reason: reason,
          context: context,
        ),
      );
    }
  }

  @override
  void setCustomKey(String key, Object value) {
    for (final delegate in _delegates) {
      delegate.setCustomKey(key, value);
    }
  }

  @override
  void setUserId(String? userId) {
    for (final delegate in _delegates) {
      delegate.setUserId(userId);
    }
  }
}
