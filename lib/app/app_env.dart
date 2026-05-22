import 'package:flutter/foundation.dart';

/// Application configuration from compile-time defines.
///
/// Release builds must pass `--dart-define=API_BASE_URL=https://your-api-host`.
class AppEnv {
  AppEnv._({
    required this.apiBaseUrl,
    required this.logNetwork,
    required this.enablePush,
    required this.privacyPolicyUrl,
    required this.minimumAppVersion,
    required this.updateUrl,
  });

  factory AppEnv.fromEnvironment() {
    const apiFromEnv = String.fromEnvironment('API_BASE_URL');
    const logNetwork = bool.fromEnvironment('LOG_NETWORK', defaultValue: false);
    const enablePush = bool.fromEnvironment('ENABLE_PUSH', defaultValue: true);
    const privacyFromEnv = String.fromEnvironment('PRIVACY_POLICY_URL');
    const minimumVersionFromEnv = String.fromEnvironment('MINIMUM_APP_VERSION');
    const updateUrlFromEnv = String.fromEnvironment('UPDATE_URL');

    final apiBaseUrl = apiFromEnv.isNotEmpty
        ? apiFromEnv
        : (kDebugMode ? 'http://localhost:3001' : '');

    final privacyPolicyUrl = privacyFromEnv.isNotEmpty
        ? privacyFromEnv
        : 'https://pranidoctor.com/privacy';

    return AppEnv._(
      apiBaseUrl: apiBaseUrl,
      logNetwork: logNetwork && kDebugMode,
      enablePush: enablePush,
      privacyPolicyUrl: privacyPolicyUrl,
      minimumAppVersion: minimumVersionFromEnv,
      updateUrl: updateUrlFromEnv,
    );
  }

  final String apiBaseUrl;
  final bool logNetwork;
  final bool enablePush;
  final String privacyPolicyUrl;

  /// Optional compile-time minimum version for force-update (until API exposes it).
  final String minimumAppVersion;

  /// Play Store / App Store URL opened from force-update screen.
  final String updateUrl;

  bool get isConfigured =>
      apiBaseUrl.isNotEmpty && !apiBaseUrl.contains('example.com');

  void assertProductionReady() {
    if (kDebugMode) return;
    if (!isConfigured) {
      throw StateError(
        'API_BASE_URL dart-define is required for release builds.',
      );
    }
  }
}
