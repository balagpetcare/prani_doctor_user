/// Contract for fatal/non-fatal error reporting (Firebase Crashlytics, webhook, etc.).
///
/// Wire a real implementation in [bootstrap] before `runApp`:
/// ```dart
/// GlobalErrorHandler.install(
///   crashReporter: resolveCrashReporter(env: env),
/// );
/// ```
abstract interface class CrashReporter {
  /// Records a caught error. Set [fatal] for unhandled framework errors.
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
    Map<String, Object?>? context,
  });

  /// Breadcrumb-style log attached to the next crash report.
  void log(String message);

  /// Associates crashes with a user id (never log PII in messages).
  void setUserId(String? userId);

  /// Custom key/value metadata on crash reports.
  void setCustomKey(String key, Object value);
}

/// No-op used when crash reporting is disabled or unconfigured.
final class NoOpCrashReporter implements CrashReporter {
  const NoOpCrashReporter();

  @override
  void log(String message) {}

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
    Map<String, Object?>? context,
  }) async {}

  @override
  void setCustomKey(String key, Object value) {}

  @override
  void setUserId(String? userId) {}
}
