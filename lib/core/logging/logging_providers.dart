import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics_reporter.dart';
import 'app_logger.dart';
import 'crash_reporter.dart';
import 'remote_log_sink.dart';

/// Injectable [CrashReporter] for tests and future Firebase wiring.
final crashReporterProvider = Provider<CrashReporter>((ref) {
  return AppLog.crashReporter;
});

/// Injectable analytics facade.
final analyticsReporterProvider = Provider<AnalyticsReporter>((ref) {
  return const NoOpAnalyticsReporter();
});

/// Injectable remote log sink.
final remoteLogSinkProvider = Provider<RemoteLogSink>((ref) {
  return AppLog.remoteSink;
});
