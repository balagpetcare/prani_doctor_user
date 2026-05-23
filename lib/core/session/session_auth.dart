import 'session_state.dart';

/// Shared auth gate for Riverpod providers and coordinators.
abstract final class SessionAuth {
  SessionAuth._();

  /// Protected mobile APIs must not run until boot restore or login has finished.
  static bool canCallProtectedApis(SessionState session) =>
      session.sessionReady && session.isAuthenticated;

  /// Assert-style check for tests and defensive early returns.
  static bool assertCanCallProtectedApis(SessionState session) {
    assert(
      canCallProtectedApis(session) ||
          (!session.isAuthenticated && session.sessionReady) ||
          (!session.sessionReady && !session.isAuthenticated),
      'Protected API called before sessionReady && isAuthenticated',
    );
    return canCallProtectedApis(session);
  }

  /// Documented protected API surface (integration / audit).
  static const protectedApiPaths = [
    '/api/mobile/me',
    '/api/mobile/settings',
    '/api/mobile/vaccines/reminders',
    '/api/mobile/notifications',
    '/api/mobile/notifications/unread-count',
    '/api/mobile/profile/dashboard-context',
  ];
}
