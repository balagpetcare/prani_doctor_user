import 'package:flutter_test/flutter_test.dart';
import 'package:pranidoctor_user/app/app_env.dart';
import 'package:pranidoctor_user/core/logging/composite_crash_reporter.dart';
import 'package:pranidoctor_user/core/logging/crash_reporter.dart';
import 'package:pranidoctor_user/core/logging/crash_reporting_context.dart';
import 'package:pranidoctor_user/core/logging/webhook_crash_reporter.dart';
import 'package:pranidoctor_user/core/network/interceptors/crash_reporting_network_interceptor.dart';

/// Verifies mobile monitoring hooks are wired without rewriting app architecture.
void main() {
  group('Monitoring readiness', () {
    test('CompositeCrashReporter fans out to multiple backends', () async {
      final a = _RecordingCrashReporter();
      final b = _RecordingCrashReporter();
      final composite = CompositeCrashReporter([a, b]);

      await composite.recordError(Exception('test'), StackTrace.current);

      expect(a.count, 1);
      expect(b.count, 1);
    });

    test('WebhookCrashReporter accepts https URL', () {
      final reporter = WebhookCrashReporter(
        webhookUrl: 'https://example.com/hook',
      );
      expect(reporter, isA<CrashReporter>());
    });

    test('CrashReportingNetworkInterceptor.shared is wired for Dio', () {
      final interceptor = CrashReportingNetworkInterceptor.shared();
      expect(interceptor, isA<CrashReportingNetworkInterceptor>());
    });

    test('CrashReportingContext snapshot includes app_env', () {
      CrashReportingContext.appEnvironment = AppEnvironment.production;
      CrashReportingContext.releaseName = '1.0.0+1';
      final snap = CrashReportingContext.snapshot();
      expect(snap['app_env'], 'production');
      expect(snap['release'], '1.0.0+1');
    });
  });
}

final class _RecordingCrashReporter implements CrashReporter {
  int count = 0;

  @override
  void log(String message) {}

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
    Map<String, Object?>? context,
  }) async {
    count++;
  }

  @override
  void setCustomKey(String key, Object value) {}

  @override
  void setUserId(String? userId) {}
}
