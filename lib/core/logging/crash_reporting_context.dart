import '../../app/app_env.dart';

/// Shared metadata attached to every crash report (env, release, build).
///
/// Updated once during bootstrap via [CrashReportingBootstrap].
abstract final class CrashReportingContext {
  CrashReportingContext._();

  static AppEnvironment appEnvironment = AppEnvironment.dev;
  static String? appVersion;
  static String? buildNumber;
  static String? releaseName;
  static String? apiHost;
  static String? localeCode;

  /// Merged into [CrashReporter.recordError] context maps.
  static Map<String, Object?> snapshot() {
    return {
      if (appVersion != null) 'app_version': appVersion,
      if (buildNumber != null) 'build_number': buildNumber,
      if (releaseName != null) 'release': releaseName,
      'app_env': appEnvironment.name,
      if (apiHost != null && apiHost!.isNotEmpty) 'api_host': apiHost,
      if (localeCode != null) 'locale': localeCode,
    };
  }
}

/// Error taxonomy ids — see docs/production/mobile/flutter-crash-reporting-plan.md
abstract final class CrashErrorCategory {
  CrashErrorCategory._();

  static const frameworkFatal = 'E01';
  static const uncaughtAsync = 'E02';
  static const widgetBuildFallback = 'E03';
  static const errorBoundary = 'E04';
  static const navigation = 'E05';
  static const networkUnexpected = 'E07';
  static const startupConfig = 'E09';
  static const bootRecoverable = 'E10';
  static const backgroundIsolate = 'E11';
  static const providerFailure = 'E12';
}
