/// Application-wide constant values.
///
/// Single source of truth for magic numbers, durations and keys that were
/// previously scattered across feature modules. Pure Dart (no Flutter import)
/// so it can be reused from any layer including tests and tooling.
abstract final class AppConstants {
  AppConstants._();

  /// Public product name (display).
  static const String appName = 'PraniDoctor';

  /// Default API list page size used by paginated repositories.
  static const int defaultPageSize = 20;

  /// Standard debounce for search inputs / rapid user actions.
  static const Duration inputDebounce = Duration(milliseconds: 350);

  /// Standard debounce applied to cache revalidation / section refresh.
  static const Duration refreshDebounce = Duration(milliseconds: 800);

  /// Default snackbar visibility duration.
  static const Duration snackbarDuration = Duration(seconds: 3);

  /// Max attempts before an outbox item is dead-lettered.
  static const int outboxMaxAttempts = 5;

  /// Default avatar / thumbnail edge size in logical pixels.
  static const double avatarSize = 96;
}
