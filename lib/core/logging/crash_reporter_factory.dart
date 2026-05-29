import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../../app/app_env.dart';
import 'composite_crash_reporter.dart';
import 'crash_reporter.dart';
import 'crash_reporting_context.dart';
import 'firebase_crashlytics_reporter.dart';
import 'sentry_crash_reporter.dart';
import 'webhook_crash_reporter.dart';

/// Whether outbound crash collection is active for this build.
bool crashReportingEnabled({required AppEnv env}) {
  const forced = bool.fromEnvironment(
    'ENABLE_CRASH_REPORTING',
    defaultValue: false,
  );
  if (forced) return true;
  return kReleaseMode;
}

/// Builds the active [CrashReporter] from compile-time env and optional Firebase.
CrashReporter resolveCrashReporter({
  required AppEnv env,
  FirebaseCrashlytics? crashlytics,
}) {
  CrashReportingContext.appEnvironment = env.environment;
  CrashReportingContext.apiHost = env.apiHost;

  if (!crashReportingEnabled(env: env)) {
    return const NoOpCrashReporter();
  }

  final reporters = <CrashReporter>[];

  if (env.isSentryActive) {
    reporters.add(SentryCrashReporter());
  }

  if (crashlytics != null) {
    reporters.add(FirebaseCrashlyticsReporter(crashlytics));
  }

  final webhookUrl = env.crashReportingWebhookUrl.trim();
  if (webhookUrl.isNotEmpty && webhookUrl.startsWith('https://')) {
    reporters.add(WebhookCrashReporter(webhookUrl: webhookUrl));
  }

  if (reporters.isEmpty) {
    return const NoOpCrashReporter();
  }
  if (reporters.length == 1) {
    return reporters.first;
  }
  return CompositeCrashReporter(reporters);
}
