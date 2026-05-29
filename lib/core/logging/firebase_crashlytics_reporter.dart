import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'crash_reporter.dart';
import 'crash_reporting_context.dart';

/// Firebase Crashlytics adapter for [CrashReporter].
final class FirebaseCrashlyticsReporter implements CrashReporter {
  FirebaseCrashlyticsReporter(this._crashlytics);

  final FirebaseCrashlytics _crashlytics;

  @override
  void log(String message) {
    _crashlytics.log(message);
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
    Map<String, Object?>? context,
  }) async {
    final merged = {...CrashReportingContext.snapshot(), ...?context};
    await _crashlytics.recordError(
      error,
      stack ?? StackTrace.current,
      fatal: fatal,
      reason: reason,
      information: merged.entries
          .map((e) => '${e.key}=${e.value}')
          .toList(growable: false),
    );
  }

  @override
  void setCustomKey(String key, Object value) {
    _crashlytics.setCustomKey(key, value);
  }

  @override
  void setUserId(String? userId) {
    _crashlytics.setUserIdentifier(userId ?? '');
  }
}
