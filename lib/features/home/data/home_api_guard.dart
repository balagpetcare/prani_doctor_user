/// Timeouts and retry limits for home dashboard API calls.
abstract final class HomeApiGuard {
  HomeApiGuard._();

  /// Max time before dashboard load is aborted and fallback UI is shown.
  static const dashboardLoadTimeout = Duration(seconds: 15);

  /// Max skeleton display before escalating to error/retry UI.
  static const skeletonMaxDisplay = Duration(seconds: 12);

  /// Per-request retry attempts (excluding cache fallback).
  static const maxApiAttempts = 2;

  static const retryDelay = Duration(milliseconds: 400);

  /// Minimum animal count before JSON list parsing moves to a background isolate.
  static const isolateParseMinItems = 24;
}
