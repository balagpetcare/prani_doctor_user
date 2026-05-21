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
  });

  factory AppEnv.fromEnvironment() {
    const apiFromEnv = String.fromEnvironment('API_BASE_URL');
    const logNetwork = bool.fromEnvironment('LOG_NETWORK', defaultValue: false);
    const enablePush = bool.fromEnvironment('ENABLE_PUSH', defaultValue: true);
    const privacyFromEnv = String.fromEnvironment('PRIVACY_POLICY_URL');

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
    );
  }

  final String apiBaseUrl;
  final bool logNetwork;
  final bool enablePush;
  final String privacyPolicyUrl;

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
