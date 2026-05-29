import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/app_env.dart';
import 'app_logger.dart';
import 'crash_reporter_factory.dart';
import 'crash_reporting_context.dart';
import 'sentry_bootstrap.dart';

/// Applies environment and release metadata to crash reporters after startup init.
abstract final class CrashReportingBootstrap {
  CrashReportingBootstrap._();

  /// Call after [AppEnv] is resolved — sets env keys before Firebase is ready.
  static void applyEnvironment(AppEnv env) {
    CrashReportingContext.appEnvironment = env.environment;
    CrashReportingContext.apiHost = env.apiHost;
    _setReporterKeys({
      'app_env': env.environment.name,
      if (env.apiHost.isNotEmpty) 'api_host': env.apiHost,
    });
  }

  /// Rebind [AppLog.crashReporter] when Firebase Crashlytics becomes available.
  static Future<void> activateFirebaseReporting(AppEnv env) async {
    try {
      final crashlytics = FirebaseCrashlytics.instance;
      await crashlytics.setCrashlyticsCollectionEnabled(
        crashReportingEnabled(env: env),
      );
      AppLog.crashReporter = resolveCrashReporter(
        env: env,
        crashlytics: crashlytics,
      );
    } catch (e, st) {
      AppLog.warn(
        'Crashlytics activation skipped',
        tag: 'CrashReporting',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Loads version/build from [PackageInfo] and pushes release keys to reporters.
  static Future<void> applyReleaseInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      CrashReportingContext.appVersion = info.version;
      CrashReportingContext.buildNumber = info.buildNumber;
      CrashReportingContext.releaseName = '${info.version}+${info.buildNumber}';
      _setReporterKeys({
        'release': CrashReportingContext.releaseName!,
        'app_version': info.version,
        'build_number': info.buildNumber,
      });
      await SentryBootstrap.applyReleaseScope(CrashReportingContext.releaseName!);
      if (kDebugMode) {
        debugPrint(
          '[CrashReporting] release=${CrashReportingContext.releaseName} '
          'env=${CrashReportingContext.appEnvironment.name}',
        );
      }
    } catch (e, st) {
      AppLog.warn(
        'Release metadata unavailable',
        tag: 'CrashReporting',
        error: e,
        stackTrace: st,
      );
    }
  }

  static void _setReporterKeys(Map<String, Object> keys) {
    for (final entry in keys.entries) {
      AppLog.crashReporter.setCustomKey(entry.key, entry.value);
    }
  }
}
