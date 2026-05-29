/// In-memory throttle to avoid flooding crash backends on repeated failures.
final class CrashReportThrottle {
  CrashReportThrottle({this.defaultInterval = const Duration(minutes: 1)});

  final Duration defaultInterval;
  final Map<String, DateTime> _lastReport = {};

  /// Returns `true` when [key] may emit a new report.
  bool allow(String key, {Duration? interval}) {
    final now = DateTime.now();
    final minGap = interval ?? defaultInterval;
    final last = _lastReport[key];
    if (last != null && now.difference(last) < minGap) {
      return false;
    }
    _lastReport[key] = now;
    return true;
  }
}
