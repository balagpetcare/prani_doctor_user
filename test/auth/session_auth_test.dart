import 'package:flutter_test/flutter_test.dart';

import 'package:pranidoctor_user/core/auth/jwt_utils.dart';
import 'package:pranidoctor_user/core/session/session_auth.dart';
import 'package:pranidoctor_user/core/session/session_state.dart';
import 'package:pranidoctor_user/features/auth/data/auth_api_paths.dart';
import 'package:pranidoctor_user/features/home/data/dashboard_api_paths.dart';
import 'package:pranidoctor_user/features/notifications/data/notification_api_paths.dart';
import 'package:pranidoctor_user/features/profile/data/profile_api_paths.dart';
import 'package:pranidoctor_user/features/settings/data/settings_api_paths.dart';
import 'package:pranidoctor_user/features/vaccine/data/vaccine_api_paths.dart';

import '../helpers/test_jwt.dart';

void main() {
  group('SessionAuth', () {
    test('blocks protected APIs until sessionReady and isAuthenticated', () {
      expect(SessionAuth.canCallProtectedApis(const SessionState()), isFalse);
      expect(
        SessionAuth.canCallProtectedApis(
          const SessionState(sessionReady: true),
        ),
        isFalse,
      );
      expect(
        SessionAuth.canCallProtectedApis(
          const SessionState(isAuthenticated: true),
        ),
        isFalse,
      );
      expect(
        SessionAuth.canCallProtectedApis(
          const SessionState(isAuthenticated: true, sessionReady: true),
        ),
        isTrue,
      );
    });

    test('documents protected API paths used by gated providers', () {
      expect(SessionAuth.protectedApiPaths, contains(ProfileApiPaths.me));
      expect(
        SessionAuth.protectedApiPaths,
        contains(SettingsApiPaths.settings),
      );
      expect(
        SessionAuth.protectedApiPaths,
        contains(VaccineApiPaths.reminders),
      );
      expect(
        SessionAuth.protectedApiPaths,
        contains(NotificationApiPaths.notifications),
      );
      expect(
        SessionAuth.protectedApiPaths,
        contains(DashboardApiPaths.dashboardContext),
      );
    });

    test('auth paths stay unauthenticated for Dio interceptor', () {
      expect(
        AuthApiPaths.isUnauthenticatedPath(AuthApiPaths.otpRequest),
        isTrue,
      );
      expect(
        AuthApiPaths.isUnauthenticatedPath(AuthApiPaths.otpVerify),
        isTrue,
      );
      expect(AuthApiPaths.isUnauthenticatedPath(ProfileApiPaths.me), isFalse);
    });
  });

  group('JwtUtils', () {
    test('rejects dev-token and non-JWT strings', () {
      expect(JwtUtils.isValidAccessToken('dev-token'), isFalse);
      expect(JwtUtils.isExpired('dev-token'), isTrue);
    });

    test('rejects JWT with unexpected audience', () {
      final token = testJwt(sub: 'bad-aud', aud: 'web-panel');
      expect(JwtUtils.isValidAccessToken(token), isFalse);
    });

    test('accepts valid unexpired JWT', () {
      final token = testJwt(sub: 'jwt-user');
      expect(JwtUtils.isValidAccessToken(token), isTrue);
      expect(JwtUtils.isExpired(token), isFalse);
      expect(JwtUtils.subject(token), 'jwt-user');
    });

    test('marks expired JWT as expired', () {
      final token = testJwt(
        sub: 'jwt-expired',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      expect(JwtUtils.isValidAccessToken(token), isTrue);
      expect(JwtUtils.isExpired(token), isTrue);
    });
  });
}
