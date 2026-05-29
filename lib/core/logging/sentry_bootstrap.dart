import 'package:sentry_flutter/sentry_flutter.dart';

import '../../app/app_env.dart';

/// Initializes the Sentry SDK when [AppEnv.isSentryActive] is true.
abstract final class SentryBootstrap {
  SentryBootstrap._();

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<void> initIfConfigured(AppEnv env) async {
    if (!env.isSentryActive) return;

    try {
      await SentryFlutter.init((options) {
        options.dsn = env.sentryDsn.trim();
        options.environment = env.environment.name;
        if (env.sentryRelease != null) {
          options.release = env.sentryRelease;
        }
        options.tracesSampleRate = env.sentryTracesSampleRate;
        options.sendDefaultPii = false;
        options.attachStacktrace = true;
        options.beforeSend = _scrubEvent;
      });
      _initialized = true;
    } catch (_) {
      // Sentry must never block app startup.
    }
  }

  static Future<void> applyReleaseScope(String releaseName) async {
    if (!_initialized || releaseName.isEmpty) return;
    await Sentry.configureScope((scope) {
      scope.setTag('release', releaseName);
    });
  }

  static SentryEvent? _scrubEvent(SentryEvent event, Hint hint) {
    final headers = event.request?.headers;
    if (headers != null) {
      headers.removeWhere(
        (key, _) => _sensitiveHeaderKeys.contains(key.toLowerCase()),
      );
    }
    return event;
  }

  static const _sensitiveHeaderKeys = {
    'authorization',
    'cookie',
    'set-cookie',
    'x-api-key',
    'x-auth-token',
  };
}
