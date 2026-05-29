import '../logging/app_logger.dart';

/// Fire-and-forget async helpers that route failures to [AppLog] + crash reporter.
abstract final class SafeAsync {
  SafeAsync._();

  /// Runs [action] and logs any uncaught error (does not rethrow).
  static Future<T?> run<T>(
    Future<T> Function() action, {
    String tag = 'Async',
    T? fallback,
  }) async {
    try {
      return await action();
    } catch (e, st) {
      AppLog.error('$tag failed', tag: tag, error: e, stackTrace: st);
      return fallback;
    }
  }

  /// Schedules [action] without awaiting; errors are logged, not propagated.
  static void fireAndForget(
    Future<dynamic> Function() action, {
    String tag = 'Async',
  }) {
    run(() async {
      await action();
    }, tag: tag);
  }
}
