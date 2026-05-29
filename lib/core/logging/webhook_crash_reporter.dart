import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'crash_reporter.dart';

/// Posts crash payloads to ERROR_TRACKING_WEBHOOK_URL (Sentry-compatible generic hook).
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
      await _dio.post<Map<String, dynamic>>(
        _webhookUrl,
        data: jsonEncode({
          'service': 'pranidoctor-user',
          'fatal': fatal,
          'reason': reason,
          'message': error.toString(),
          'stack': stack?.toString(),
          'context': context,
          'env': kReleaseMode ? 'release' : 'debug',
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

/// Selects webhook reporter when configured, otherwise no-op.
CrashReporter resolveCrashReporter({String? webhookUrl}) {
  final url = webhookUrl?.trim() ?? '';
  if (url.isNotEmpty && url.startsWith('https://')) {
    return WebhookCrashReporter(webhookUrl: url);
  }
  return const NoOpCrashReporter();
}
