import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../logging/app_logger.dart';
import '../logging/crash_reporter.dart';
import '../../shared/widgets/app_graceful_error.dart';

/// Installs framework-wide error handlers before [runApp].
///
/// Call once from [bootstrap] inside [runZonedGuarded]:
/// ```dart
/// GlobalErrorHandler.install();
/// runZonedGuarded(() async { ... runApp(...); }, GlobalErrorHandler.handleZoneError);
/// ```
abstract final class GlobalErrorHandler {
  GlobalErrorHandler._();

  static bool _installed = false;

  /// Registers Flutter, platform, and [ErrorWidget] handlers.
  static void install({CrashReporter? crashReporter}) {
    if (_installed) return;
    _installed = true;

    if (crashReporter != null) {
      AppLog.crashReporter = crashReporter;
    }

    FlutterError.onError = _onFlutterError;

    PlatformDispatcher.instance.onError = _onPlatformError;

    ErrorWidget.builder = (FlutterErrorDetails details) {
      AppLog.error(
        'ErrorWidget',
        tag: 'UI',
        error: details.exception,
        stackTrace: details.stack,
        reportToCrashReporter: true,
        fatal: false,
      );
      return AppGracefulErrorWidget(details: details);
    };
  }

  static void _onFlutterError(FlutterErrorDetails details) {
    final exception = details.exception;
    final stack = details.stack ?? StackTrace.current;

    AppLog.error(
      'Flutter framework error',
      tag: 'FlutterError',
      error: exception,
      stackTrace: stack,
      fatal: true,
    );

    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  }

  static bool _onPlatformError(Object error, StackTrace stack) {
    AppLog.error(
      'Uncaught async error',
      tag: 'Platform',
      error: error,
      stackTrace: stack,
      fatal: true,
    );
    return true;
  }

  /// Zone error callback for [runZonedGuarded].
  static void handleZoneError(Object error, StackTrace stack) {
    AppLog.error(
      'Zone error',
      tag: 'Zone',
      error: error,
      stackTrace: stack,
      fatal: true,
    );
  }

  /// Runs [body] inside a guarded zone with global handlers installed.
  static Future<void> runGuarded(
    Future<void> Function() body, {
    CrashReporter? crashReporter,
  }) async {
    install(crashReporter: crashReporter);
    await runZonedGuarded(
      () async => body(),
      handleZoneError,
    );
  }
}
