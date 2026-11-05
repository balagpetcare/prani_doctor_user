import 'dart:async';

import '../startup/startup_trace.dart';

/// Runs [action] with a hard timeout and structured startup/API logging.
Future<T> runWithTimeout<T>({
  required String label,
  required Duration timeout,
  required Future<T> Function() action,
  T Function(Object error)? onTimeout,
}) async {
  StartupTrace.apiStart(label);
  try {
    final result = await action().timeout(timeout);
    StartupTrace.apiSuccess(label);
    return result;
  } on TimeoutException catch (e) {
    StartupTrace.apiFailure(label, e, detail: 'timeout');
    if (onTimeout != null) return onTimeout(e);
    rethrow;
  } catch (e) {
    StartupTrace.apiFailure(label, e);
    rethrow;
  }
}
