import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import '../core/network/network_constants.dart';

/// How [AppEnv.apiBaseUrl] was resolved at compile time.
enum ApiUrlSource { explicitBaseUrl, hostAndPort, devPlatformDefault, unset }

/// Supported deployment targets for compile-time configuration.
enum AppEnvironment { dev, staging, production }

/// Application configuration from compile-time defines.
///
/// Mobile app targets **pranidoctor-backend** (default port **3000**).
/// Admin web (pranidoctor-web) defaults to port **3001** — reference only via [webBaseUrl].
///
/// Physical device (dev default): `http://<PC_WIFI_IP>:3000`
/// Override via `API_BASE_URL` or `DEV_WIFI_HOST` dart-define / `.env`.
/// Android emulator: set `API_BASE_URL=http://10.0.2.2:3000` in `.env`.
class AppEnv {
  AppEnv._({
    required this.environment,
    required this.apiBaseUrl,
    required this.apiUrlSource,
    required this.apiHost,
    required this.apiPort,
    required this.webBaseUrl,
    required this.logNetwork,
    required this.enablePush,
    required this.privacyPolicyUrl,
    required this.termsOfServiceUrl,
    required this.crashReportingWebhookUrl,
    required this.sentryDsn,
    required this.sentryReleaseFromEnv,
    required this.sentryTracesSampleRate,
    required this.minimumAppVersion,
    required this.updateUrl,
    required this.uploadBaseUrl,
    required this.connectTimeout,
    required this.receiveTimeout,
  });

  factory AppEnv.fromEnvironment() {
    const appEnvRaw = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
    const apiFromEnv = String.fromEnvironment('API_BASE_URL');
    const apiHost = String.fromEnvironment('API_HOST');
    const apiPortRaw = String.fromEnvironment(
      'API_PORT',
      defaultValue: '${NetworkConstants.defaultApiPort}',
    );
    const devWifiHost = String.fromEnvironment(
      'DEV_WIFI_HOST',
      defaultValue: NetworkConstants.defaultDevWifiHost,
    );
    const webFromEnv = String.fromEnvironment('WEB_BASE_URL');
    const webPortRaw = String.fromEnvironment(
      'WEB_PORT',
      defaultValue: '${NetworkConstants.defaultWebPort}',
    );
    const logNetwork = bool.fromEnvironment('LOG_NETWORK', defaultValue: false);
    const enablePush = bool.fromEnvironment('ENABLE_PUSH', defaultValue: true);
    const privacyFromEnv = String.fromEnvironment('PRIVACY_POLICY_URL');
    const termsFromEnv = String.fromEnvironment('TERMS_OF_SERVICE_URL');
    const crashWebhookFromEnv = String.fromEnvironment('CRASH_REPORTING_WEBHOOK_URL');
    const sentryDsnFromEnv = String.fromEnvironment('SENTRY_DSN');
    const appVersionFromEnv = String.fromEnvironment('APP_VERSION');
    const sentrySampleRateRaw = String.fromEnvironment(
      'SENTRY_TRACES_SAMPLE_RATE',
      defaultValue: '0.1',
    );
    const minimumVersionFromEnv = String.fromEnvironment('MINIMUM_APP_VERSION');
    const updateUrlFromEnv = String.fromEnvironment('UPDATE_URL');
    const uploadUrlFromEnv = String.fromEnvironment('UPLOAD_URL');
    const connectSec = int.fromEnvironment(
      'API_CONNECT_TIMEOUT_SEC',
      defaultValue: NetworkConstants.defaultConnectTimeoutSec,
    );
    const receiveSec = int.fromEnvironment(
      'API_RECEIVE_TIMEOUT_SEC',
      defaultValue: NetworkConstants.defaultReceiveTimeoutSec,
    );

    final environment = _parseEnvironment(appEnvRaw);
    final apiPort = int.tryParse(apiPortRaw) ?? NetworkConstants.defaultApiPort;
    final webPort = int.tryParse(webPortRaw) ?? NetworkConstants.defaultWebPort;

    final resolved = _resolveApiBaseUrl(
      environment: environment,
      apiFromEnv: apiFromEnv,
      apiHost: apiHost,
      apiPort: apiPort,
      devWifiHost: devWifiHost,
    );

    final webBaseUrl = _resolveWebBaseUrl(
      webFromEnv: webFromEnv,
      apiHost: resolved.host,
      webPort: webPort,
      environment: environment,
    );

    final uploadBaseUrl = uploadUrlFromEnv.trim().isNotEmpty
        ? _normalizeBaseUrl(uploadUrlFromEnv.trim())
        : resolved.url;

    return AppEnv._(
      environment: environment,
      apiBaseUrl: resolved.url,
      apiUrlSource: resolved.source,
      apiHost: resolved.host,
      apiPort: apiPort,
      webBaseUrl: webBaseUrl,
      logNetwork: logNetwork && kDebugMode,
      enablePush: enablePush,
      privacyPolicyUrl: privacyFromEnv.isNotEmpty
          ? privacyFromEnv
          : 'https://pranidoctor.com/privacy',
      termsOfServiceUrl: termsFromEnv.isNotEmpty
          ? termsFromEnv
          : 'https://pranidoctor.com/terms',
      crashReportingWebhookUrl: crashWebhookFromEnv,
      sentryDsn: sentryDsnFromEnv,
      sentryReleaseFromEnv: appVersionFromEnv.isNotEmpty
          ? 'pranidoctor-mobile@$appVersionFromEnv'
          : '',
      sentryTracesSampleRate: _parseSampleRate(sentrySampleRateRaw),
      minimumAppVersion: minimumVersionFromEnv,
      updateUrl: updateUrlFromEnv,
      uploadBaseUrl: uploadBaseUrl,
      connectTimeout: Duration(seconds: connectSec.clamp(5, 120)),
      receiveTimeout: Duration(seconds: receiveSec.clamp(5, 120)),
    );
  }

  final AppEnvironment environment;
  final String apiBaseUrl;
  final ApiUrlSource apiUrlSource;
  final String apiHost;
  final int apiPort;
  final String webBaseUrl;
  final bool logNetwork;
  final bool enablePush;
  final String privacyPolicyUrl;
  final String termsOfServiceUrl;
  final String crashReportingWebhookUrl;
  final String sentryDsn;
  final String sentryReleaseFromEnv;
  final double sentryTracesSampleRate;
  final String minimumAppVersion;
  final String updateUrl;
  final String uploadBaseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;

  bool get isDev => environment == AppEnvironment.dev;

  /// Sentry release tag — CI [APP_VERSION] or runtime package info suffix.
  String? get sentryRelease =>
      sentryReleaseFromEnv.trim().isNotEmpty ? sentryReleaseFromEnv.trim() : null;

  /// True when Sentry DSN is set, enabled, and crash reporting is active for build.
  bool get isSentryActive {
    if (sentryDsn.trim().isEmpty) return false;
    const enabled = bool.fromEnvironment('SENTRY_ENABLED', defaultValue: true);
    if (!enabled) return false;
    const forced = bool.fromEnvironment(
      'ENABLE_CRASH_REPORTING',
      defaultValue: false,
    );
    if (forced) return true;
    return kReleaseMode;
  }

  bool get isConfigured =>
      apiBaseUrl.isNotEmpty && !apiBaseUrl.contains('example.com');

  bool get usesLocalhost =>
      apiBaseUrl.contains('localhost') || apiBaseUrl.contains('127.0.0.1');

  bool get usesCleartextHttp =>
      apiBaseUrl.startsWith('http://') || uploadBaseUrl.startsWith('http://');

  String get apiUrlSourceLabel => switch (apiUrlSource) {
    ApiUrlSource.explicitBaseUrl => 'API_BASE_URL',
    ApiUrlSource.hostAndPort => 'API_HOST + API_PORT',
    ApiUrlSource.devPlatformDefault => 'dev platform default',
    ApiUrlSource.unset => 'unset',
  };

  void assertProductionReady() {
    if (kDebugMode) return;
    if (!isConfigured) {
      throw StateError(
        'API_BASE_URL dart-define is required for release builds.',
      );
    }
    if (environment == AppEnvironment.production && usesCleartextHttp) {
      throw StateError(
        'Production builds must use HTTPS for API_BASE_URL and UPLOAD_URL.',
      );
    }
    if (environment == AppEnvironment.staging && usesCleartextHttp) {
      throw StateError(
        'Staging builds must use HTTPS for API_BASE_URL and UPLOAD_URL.',
      );
    }
    if (environment == AppEnvironment.production &&
        !privacyPolicyUrl.startsWith('https://')) {
      throw StateError(
        'PRIVACY_POLICY_URL must be an HTTPS URL for production release.',
      );
    }
  }

  /// Call after Firebase bootstrap when [enablePush] is true.
  void assertPushReady({required bool firebaseReady}) {
    if (kDebugMode || !enablePush) return;
    if (!firebaseReady) {
      throw StateError(
        'ENABLE_PUSH=true requires google-services.json and Firebase options.',
      );
    }
  }

  void logDebugSummary() {
    if (!kDebugMode) return;
    debugPrint('[API] Active base URL: $apiBaseUrl');
    debugPrint(
      '[AppEnv] env=${environment.name} api=$apiBaseUrl '
      'source=$apiUrlSourceLabel web=$webBaseUrl '
      'timeouts=${connectTimeout.inSeconds}s push=$enablePush logNetwork=$logNetwork',
    );
    if (usesLocalhost && !kIsWeb) {
      try {
        if (Platform.isAndroid) {
          debugPrint(
            '[AppEnv] localhost on Android fails on a physical device. '
            'Use API_BASE_URL=http://<PC_WIFI_IP>:$apiPort',
          );
        }
      } catch (_) {}
    }
  }

  static double _parseSampleRate(String raw) {
    final parsed = double.tryParse(raw.trim());
    if (parsed == null || parsed.isNaN) return 0.1;
    if (parsed < 0) return 0;
    if (parsed > 1) return 1;
    return parsed;
  }

  static AppEnvironment _parseEnvironment(String raw) {
    switch (raw.toLowerCase()) {
      case 'staging':
        return AppEnvironment.staging;
      case 'production':
      case 'prod':
        return AppEnvironment.production;
      default:
        return AppEnvironment.dev;
    }
  }

  static _ResolvedApi _resolveApiBaseUrl({
    required AppEnvironment environment,
    required String apiFromEnv,
    required String apiHost,
    required int apiPort,
    required String devWifiHost,
  }) {
    final explicit = apiFromEnv.trim();
    if (explicit.isNotEmpty) {
      final url = _normalizeBaseUrl(explicit);
      return _ResolvedApi(
        url: url,
        source: ApiUrlSource.explicitBaseUrl,
        host: _extractHost(url),
      );
    }

    if (apiHost.trim().isNotEmpty) {
      final host = apiHost.trim();
      final url = host.startsWith('http://') || host.startsWith('https://')
          ? _normalizeBaseUrl(host)
          : _normalizeBaseUrl(
              '${environment == AppEnvironment.production ? 'https' : 'http'}://$host:$apiPort',
            );
      return _ResolvedApi(
        url: url,
        source: ApiUrlSource.hostAndPort,
        host: _extractHost(url),
      );
    }

    if (kDebugMode && environment == AppEnvironment.dev) {
      final url = _normalizeBaseUrl(
        NetworkConstants.devWifiApiBaseUrl(
          host: devWifiHost.trim().isNotEmpty
              ? devWifiHost.trim()
              : NetworkConstants.defaultDevWifiHost,
          port: apiPort,
        ),
      );
      return _ResolvedApi(
        url: url,
        source: ApiUrlSource.devPlatformDefault,
        host: _extractHost(url),
      );
    }

    return const _ResolvedApi(url: '', source: ApiUrlSource.unset, host: '');
  }

  static String _resolveWebBaseUrl({
    required String webFromEnv,
    required String apiHost,
    required int webPort,
    required AppEnvironment environment,
  }) {
    if (webFromEnv.trim().isNotEmpty) {
      return _normalizeBaseUrl(webFromEnv.trim());
    }
    if (apiHost.isNotEmpty) {
      final scheme = environment == AppEnvironment.production
          ? 'https'
          : 'http';
      return '$scheme://$apiHost:$webPort';
    }
    return NetworkConstants.devWifiApiBaseUrl(port: webPort);
  }

  static String _normalizeBaseUrl(String url) {
    var normalized = url.trim();
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  static String _extractHost(String url) {
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return '';
    }
  }
}

class _ResolvedApi {
  const _ResolvedApi({
    required this.url,
    required this.source,
    required this.host,
  });

  final String url;
  final ApiUrlSource source;
  final String host;
}
