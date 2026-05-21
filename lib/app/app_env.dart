/// Application configuration from compile-time defines.
/// Run: `flutter run --dart-define=API_BASE_URL=https://api.example.com`
class AppEnv {
  AppEnv._({
    required this.apiBaseUrl,
    required this.logNetwork,
    required this.enablePush,
  });

  factory AppEnv.fromEnvironment() {
    const api = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://api.example.com',
    );
    const logNetwork = bool.fromEnvironment(
      'LOG_NETWORK',
      defaultValue: false,
    );
    const enablePush = bool.fromEnvironment(
      'ENABLE_PUSH',
      defaultValue: true,
    );
    return AppEnv._(
      apiBaseUrl: api,
      logNetwork: logNetwork,
      enablePush: enablePush,
    );
  }

  final String apiBaseUrl;
  final bool logNetwork;
  final bool enablePush;
}
