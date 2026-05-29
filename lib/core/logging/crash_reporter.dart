/// Contract for fatal/non-fatal error reporting (Firebase Crashlytics, Sentry, etc.).
///
/// Wire a real implementation in [bootstrap] before `runApp`:
/// ```dart
/// GlobalErrorHandler.install(
///   crashReporter: FirebaseCrashlyticsReporter(),
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

/// No-op used until Crashlytics/Sentry is configured.
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

/// Placeholder for `firebase_crashlytics` integration.
///
/// Add `firebase_crashlytics` to `pubspec.yaml`, then implement:
/// ```dart
/// final class FirebaseCrashlyticsReporter implements CrashReporter {
///   FirebaseCrashlyticsReporter(this._crashlytics);
///   final FirebaseCrashlytics _crashlytics;
///   // recordError → _crashlytics.recordError(...)
/// }
/// ```
final class FirebaseCrashlyticsReporter implements CrashReporter {
  const FirebaseCrashlyticsReporter();

  @override
  void log(String message) {
    // FirebaseCrashlytics.instance.log(message);
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
    Map<String, Object?>? context,
  }) async {
    // await FirebaseCrashlytics.instance.recordError(error, stack, fatal: fatal, reason: reason);
  }

  @override
  void setCustomKey(String key, Object value) {
    // FirebaseCrashlytics.instance.setCustomKey(key, value);
  }

  @override
  void setUserId(String? userId) {
    // FirebaseCrashlytics.instance.setUserIdentifier(userId ?? '');
  }
}
