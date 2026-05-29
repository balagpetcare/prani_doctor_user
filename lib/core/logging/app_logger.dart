import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'crash_reporter.dart';
import 'crash_reporting_context.dart';
import 'log_level.dart';
import 'log_redactor.dart';
import 'remote_log_sink.dart';

/// Structured application logger.
///
/// - **Debug** logs are suppressed in release (`kDebugMode` gate).
/// - **Info/Warn/Error** always flow to `dart:developer` log (visible in DevTools).
/// - Sensitive substrings are redacted via [LogRedactor].
/// - Fatal errors are forwarded to [CrashReporter] when configured.
abstract final class AppLog {
  AppLog._();

  static CrashReporter crashReporter = const NoOpCrashReporter();
  static RemoteLogSink remoteSink = const NoOpRemoteLogSink();

  /// When `false`, [debug] calls are no-ops (default: [kDebugMode]).
  static bool debugEnabled = kDebugMode;

  static void debug(
    String message, {
    String tag = 'App',
    Map<String, Object?>? data,
  }) {
    if (!debugEnabled) return;
    _emit(LogLevel.debug, message, tag: tag, data: data);
  }

  static void info(
    String message, {
    String tag = 'App',
    Map<String, Object?>? data,
  }) {
    _emit(LogLevel.info, message, tag: tag, data: data);
  }

  static void warn(
    String message, {
    String tag = 'App',
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? data,
  }) {
    _emit(
      LogLevel.warn,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  static void error(
    String message, {
    String tag = 'App',
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? data,
    bool reportToCrashReporter = true,
    bool fatal = false,
  }) {
    _emit(
      LogLevel.error,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
    if (reportToCrashReporter && error != null) {
      unawaited(
        crashReporter.recordError(
          error,
          stackTrace,
          fatal: fatal,
          reason: message,
          context: {
            ...CrashReportingContext.snapshot(),
            ...?data,
          },
        ),
      );
    }
  }

  static void _emit(
    LogLevel level,
    String message, {
    required String tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? data,
  }) {
    final safeMessage = LogRedactor.redact(message);
    final line = '[$tag] ${level.label}: $safeMessage';
    developer.log(
      line,
      name: tag,
      level: _developerLevel(level),
      error: error,
      stackTrace: stackTrace,
    );
    remoteSink.write(
      level: level,
      message: safeMessage,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  static int _developerLevel(LogLevel level) => switch (level) {
    LogLevel.debug => 500,
    LogLevel.info => 800,
    LogLevel.warn => 900,
    LogLevel.error => 1000,
  };
}
