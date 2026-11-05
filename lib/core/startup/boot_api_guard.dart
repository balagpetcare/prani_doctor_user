/// Timeouts and retry limits for cold-start / boot APIs.
abstract final class BootApiGuard {
  BootApiGuard._();

  static const configLoadTimeout = Duration(seconds: 12);
  static const sessionRestoreTimeout = Duration(seconds: 15);
  static const profileFetchTimeout = Duration(seconds: 12);
  static const splashMaxDisplay = Duration(seconds: 20);
  static const maxAttempts = 2;
  static const retryDelay = Duration(milliseconds: 400);
}
