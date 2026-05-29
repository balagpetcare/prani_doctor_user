import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'crash_reporter.dart';
import 'crash_reporting_context.dart';
import 'log_redactor.dart';

/// Posts crash payloads to CRASH_REPORTING_WEBHOOK_URL (generic ingest hook).
final class WebhookCrashReporter implements CrashReporter {
  WebhookCrashReporter({
    required String webhookUrl,
    Dio? dio,
  })  : _webhookUrl = webhookUrl,
        _dio = dio ?? Dio();

  final String _webhookUrl;
  final Dio _dio;

  @override
  void log(String message) {
    if (kDebugMode) {
      debugPrint('[CrashReporter] $message');
    }
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
    Map<String, Object?>? context,
  }) async {
    try {
      final mergedContext = {
        ...CrashReportingContext.snapshot(),
        ...?context,
      };
      await _dio.post<Map<String, dynamic>>(
        _webhookUrl,
        data: jsonEncode({
          'service': 'pranidoctor-user',
          'fatal': fatal,
          'reason': reason != null ? LogRedactor.redact(reason) : null,
          'message': LogRedactor.redact(error.toString()),
          'stack': stack?.toString(),
          'context': mergedContext,
          'env': kReleaseMode ? 'release' : 'debug',
          'app_env': CrashReportingContext.appEnvironment.name,
          if (CrashReportingContext.releaseName != null)
            'release': CrashReportingContext.releaseName,
        }),
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CrashReporter] webhook failed: $e');
      }
    }
  }

  @override
  void setCustomKey(String key, Object value) {}

  @override
  void setUserId(String? userId) {}
}
