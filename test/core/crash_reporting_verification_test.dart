import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pranidoctor_user/app/app_env.dart';
import 'package:pranidoctor_user/core/errors/global_error_handler.dart';
import 'package:pranidoctor_user/core/logging/app_logger.dart';
import 'package:pranidoctor_user/core/logging/composite_crash_reporter.dart';
import 'package:pranidoctor_user/core/logging/crash_reporter.dart';
import 'package:pranidoctor_user/core/logging/crash_reporter_factory.dart';
import 'package:pranidoctor_user/core/logging/crash_report_throttle.dart';
import 'package:pranidoctor_user/core/logging/crash_reporting_context.dart';
import 'package:pranidoctor_user/core/logging/log_redactor.dart';
import 'package:pranidoctor_user/core/logging/webhook_crash_reporter.dart';
import 'package:pranidoctor_user/core/network/interceptors/crash_reporting_network_interceptor.dart';

/// Records crash reporter invocations for assertions.
final class RecordingCrashReporter implements CrashReporter {
  final errors = <RecordedCrash>[];
  final logs = <String>[];
  String? userId;
  final customKeys = <String, Object>{};

  @override
  void log(String message) => logs.add(message);

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
    Map<String, Object?>? context,
  }) async {
    errors.add(
      RecordedCrash(
        error: error,
        stack: stack,
        fatal: fatal,
        reason: reason,
        context: context,
      ),
    );
  }

  @override
  void setCustomKey(String key, Object value) => customKeys[key] = value;

  @override
  void setUserId(String? userId) => this.userId = userId;
}

final class RecordedCrash {
  RecordedCrash({
    required this.error,
    required this.stack,
    required this.fatal,
    required this.reason,
    required this.context,
  });

  final Object error;
  final StackTrace? stack;
  final bool fatal;
  final String? reason;
  final Map<String, Object?>? context;
}

Dio _captureDio(void Function(Map<String, dynamic> body) onCapture) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        onCapture(jsonDecode(options.data as String) as Map<String, dynamic>);
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: <String, dynamic>{},
          ),
        );
      },
    ),
  );
  return dio;
}

void main() {
  group('Crash reporting verification', () {
    late RecordingCrashReporter recorder;

    setUp(() {
      recorder = RecordingCrashReporter();
      AppLog.crashReporter = recorder;
      CrashReportingContext.appEnvironment = AppEnvironment.production;
      CrashReportingContext.appVersion = '1.0.0';
      CrashReportingContext.buildNumber = '42';
      CrashReportingContext.releaseName = '1.0.0+42';
      CrashReportingContext.apiHost = 'api.example.com';
    });

    tearDown(() {
      AppLog.crashReporter = const NoOpCrashReporter();
    });

    group('V1 — Crash capture (framework / UI paths)', () {
      test('zone handler records fatal async error with E02 category', () async {
        final error = StateError('zone test');
        final stack = StackTrace.current;

        GlobalErrorHandler.handleZoneError(error, stack);
        await pumpEventQueue();

        expect(recorder.errors, hasLength(1));
        expect(recorder.errors.single.fatal, isTrue);
        expect(recorder.errors.single.context?['category'], CrashErrorCategory.uncaughtAsync);
        expect(recorder.errors.single.error, error);
      });

      test('AppLog.error attaches release context snapshot', () async {
        AppLog.error(
          'UI crash',
          tag: 'UI',
          error: Exception('widget fail'),
          stackTrace: StackTrace.current,
          fatal: false,
          data: {'category': CrashErrorCategory.widgetBuildFallback},
        );
        await pumpEventQueue();

        expect(recorder.errors.single.context?['release'], '1.0.0+42');
        expect(recorder.errors.single.context?['app_env'], 'production');
        expect(recorder.errors.single.context?['api_host'], 'api.example.com');
        expect(
          recorder.errors.single.context?['category'],
          CrashErrorCategory.widgetBuildFallback,
        );
      });
    });

    group('V2 — Async exception capture', () {
      test('runZonedGuarded routes uncaught async errors to recorder', () async {
        final asyncRecorder = RecordingCrashReporter();
        await runZonedGuarded(() async {
          AppLog.crashReporter = asyncRecorder;
          Future<void>.delayed(Duration.zero, () => throw Exception('async boom'));
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }, GlobalErrorHandler.handleZoneError);

        await pumpEventQueue(times: 5);

        expect(asyncRecorder.errors, isNotEmpty);
        expect(
          asyncRecorder.errors.any(
            (e) => e.context?['category'] == CrashErrorCategory.uncaughtAsync,
          ),
          isTrue,
        );
      });
    });

    group('V3 — Startup / boot capture', () {
      test('boot recoverable category is reportable via AppLog', () async {
        AppLog.error(
          'Boot config failed',
          tag: 'Boot',
          error: Exception('config offline'),
          fatal: false,
          data: {
            'category': CrashErrorCategory.bootRecoverable,
            'code': 'OFFLINE',
          },
        );
        await pumpEventQueue();

        expect(recorder.errors.single.fatal, isFalse);
        expect(
          recorder.errors.single.context?['category'],
          CrashErrorCategory.bootRecoverable,
        );
      });
    });

    group('V4 — Release tagging', () {
      test('webhook payload includes service, release, and app_env', () async {
        Map<String, dynamic>? payload;
        final reporter = WebhookCrashReporter(
          webhookUrl: 'https://hooks.example.com/crash',
          dio: _captureDio((body) => payload = body),
        );

        await reporter.recordError(
          Exception('test'),
          StackTrace.current,
          fatal: true,
          reason: 'verification',
          context: {'category': CrashErrorCategory.frameworkFatal},
        );

        expect(payload, isNotNull);
        final body = payload!;
        expect(body['service'], 'pranidoctor-user');
        expect(body['release'], '1.0.0+42');
        expect(body['app_env'], 'production');
        expect(body['fatal'], isTrue);
        expect(body['context'], isA<Map>());
        expect(
          (body['context'] as Map)['category'],
          CrashErrorCategory.frameworkFatal,
        );
      });

      test('composite reporter fans out to all delegates', () async {
        final second = RecordingCrashReporter();
        final composite = CompositeCrashReporter([recorder, second]);

        await composite.recordError(
          Exception('fan-out'),
          StackTrace.current,
          fatal: false,
        );
        await pumpEventQueue(times: 5);

        expect(recorder.errors, hasLength(1));
        expect(second.errors, hasLength(1));
      });
    });

    group('V5 — Production safety', () {
      test('debug build resolves to NoOp without ENABLE_CRASH_REPORTING', () {
        final env = AppEnv.fromEnvironment();
        final reporter = resolveCrashReporter(env: env);
        expect(reporter, isA<NoOpCrashReporter>());
      });

      test('LogRedactor strips bearer tokens from webhook-bound strings', () {
        const raw = 'Bearer secret-token-xyz';
        expect(LogRedactor.redact(raw), '[REDACTED]');
        expect(LogRedactor.redact(raw), isNot(contains('secret-token')));
      });

      test('network interceptor skips expected 401 failures', () async {
        final localRecorder = RecordingCrashReporter();
        AppLog.crashReporter = localRecorder;
        final interceptor = CrashReportingNetworkInterceptor(
          throttle: CrashReportThrottle(defaultInterval: Duration.zero),
        );
        final handler = _TestErrorHandler();

        interceptor.onError(
          DioException(
            requestOptions: RequestOptions(path: '/api/mobile/me'),
            response: Response(
              requestOptions: RequestOptions(path: '/api/mobile/me'),
              statusCode: 401,
            ),
            type: DioExceptionType.badResponse,
          ),
          handler,
        );
        await pumpEventQueue();

        expect(localRecorder.errors, isEmpty);
        expect(handler.forwarded, isTrue);
      });

      test('network interceptor reports 503 with throttle', () async {
        final localRecorder = RecordingCrashReporter();
        AppLog.crashReporter = localRecorder;
        final throttle = CrashReportThrottle(
          defaultInterval: const Duration(minutes: 1),
        );
        final interceptor = CrashReportingNetworkInterceptor(throttle: throttle);
        final handler = _TestErrorHandler();

        final err = DioException(
          requestOptions: RequestOptions(
            method: 'GET',
            path: '/api/mobile/farms',
          ),
          response: Response(
            requestOptions: RequestOptions(path: '/api/mobile/farms'),
            statusCode: 503,
          ),
          type: DioExceptionType.badResponse,
        );

        interceptor.onError(err, handler);
        interceptor.onError(err, handler);
        await pumpEventQueue();

        expect(localRecorder.errors, hasLength(1));
        expect(
          localRecorder.errors.single.context?['category'],
          CrashErrorCategory.networkUnexpected,
        );
        expect(localRecorder.errors.single.fatal, isFalse);
      });

      test('CrashReportThrottle suppresses duplicate keys within interval', () {
        final throttle = CrashReportThrottle(
          defaultInterval: const Duration(minutes: 5),
        );
        expect(throttle.allow('GET:/farms'), isTrue);
        expect(throttle.allow('GET:/farms'), isFalse);
        expect(throttle.allow('POST:/farms'), isTrue);
      });
    });
  });
}

final class _TestErrorHandler extends ErrorInterceptorHandler {
  bool forwarded = true;

  @override
  void next(DioException err) {
    forwarded = true;
  }
}
