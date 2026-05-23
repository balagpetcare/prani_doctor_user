import 'package:flutter_test/flutter_test.dart';

import 'package:pranidoctor_user/core/session/session_auth.dart';
import 'package:pranidoctor_user/core/session/session_state.dart';
import 'package:pranidoctor_user/core/utils/version_utils.dart';
import 'package:pranidoctor_user/features/auth/data/auth_dto.dart';
import 'package:pranidoctor_user/features/auth/data/auth_validators.dart';

import '../helpers/test_jwt.dart';

void main() {
  group('Auth DTO mapping', () {
    test('OtpRequestResultDto parses compat payload', () {
      final dto = OtpRequestResultDto.fromJson({
        'sent': true,
        'otpTtlSeconds': 900,
      });
      expect(dto.sent, isTrue);
      expect(dto.otpTtlSeconds, 900);
      expect(dto.resendCooldownSeconds, 60);
    });

    test('AuthTokensDto parses refresh rotation payload', () {
      final dto = AuthTokensDto.fromJson({
        'accessToken': 'access',
        'expiresInSeconds': 3600,
        'refreshToken': 'refresh',
        'refreshExpiresInSeconds': 86400,
        'user': {'id': 'u1', 'name': 'Test User', 'mobile': '+8801612345678'},
      });
      expect(dto.accessToken, 'access');
      expect(dto.refreshToken, 'refresh');
      expect(dto.user?.id, 'u1');
    });
  });

  group('AuthValidators', () {
    test('accepts BD local and E.164 phone numbers', () {
      expect(
        AuthValidators.validatePhone(
          '01712345678',
          requiredMessage: 'required',
          invalidMessage: 'invalid',
        ),
        isNull,
      );
      expect(
        AuthValidators.validatePhone(
          '+8801712345678',
          requiredMessage: 'required',
          invalidMessage: 'invalid',
        ),
        isNull,
      );
    });

    test('rejects invalid phone numbers', () {
      expect(
        AuthValidators.validatePhone(
          '12345',
          requiredMessage: 'required',
          invalidMessage: 'invalid',
        ),
        'invalid',
      );
    });

    test('enforces minimum password length', () {
      expect(
        AuthValidators.validatePassword(
          '12345',
          requiredMessage: 'required',
          weakMessage: 'weak',
        ),
        'weak',
      );
      expect(
        AuthValidators.validatePassword(
          '123456',
          requiredMessage: 'required',
          weakMessage: 'weak',
        ),
        isNull,
      );
    });

    test('validates OTP code length', () {
      expect(
        AuthValidators.validateOtp(
          '12',
          requiredMessage: 'required',
          invalidMessage: 'invalid',
        ),
        'invalid',
      );
      expect(
        AuthValidators.validateOtp(
          '123456',
          requiredMessage: 'required',
          invalidMessage: 'invalid',
        ),
        isNull,
      );
    });

    test('allows empty optional email', () {
      expect(
        AuthValidators.validateEmailOptional('', invalidMessage: 'invalid'),
        isNull,
      );
    });
  });

  group('Auth state transition helpers', () {
    test('VersionUtils supports force-update gate', () {
      expect(VersionUtils.isBelowMinimum('1.0.0', '1.1.0'), isTrue);
      expect(VersionUtils.isBelowMinimum('1.1.0', '1.0.0'), isFalse);
      expect(VersionUtils.isBelowMinimum('1.0.0', '1.0.0'), isFalse);
    });

    test('OTP login success enables protected API gate', () {
      final token = testJwt(sub: 'otp-user');
      final dto = AuthTokensDto.fromJson({
        'accessToken': token,
        'expiresInSeconds': 3600,
        'refreshToken': 'rt',
      });
      expect(dto.accessToken, token);
      expect(
        SessionAuth.canCallProtectedApis(
          const SessionState(isAuthenticated: true, sessionReady: true),
        ),
        isTrue,
      );
    });

    test('pseudo-auth states stay blocked', () {
      expect(
        SessionAuth.canCallProtectedApis(
          const SessionState(isAuthenticated: true),
        ),
        isFalse,
      );
      expect(
        SessionAuth.canCallProtectedApis(
          const SessionState(sessionReady: true),
        ),
        isFalse,
      );
    });
  });
}
