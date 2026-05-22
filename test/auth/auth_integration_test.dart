import 'package:flutter_test/flutter_test.dart';

import 'package:pranidoctor_user/core/utils/version_utils.dart';
import 'package:pranidoctor_user/features/auth/data/auth_dto.dart';

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
        'user': {
          'id': 'u1',
          'name': 'Test User',
          'mobile': '+8801612345678',
        },
      });
      expect(dto.accessToken, 'access');
      expect(dto.refreshToken, 'refresh');
      expect(dto.user?.id, 'u1');
    });
  });

  group('Auth state transition helpers', () {
    test('VersionUtils supports force-update gate', () {
      expect(VersionUtils.isBelowMinimum('1.0.0', '1.1.0'), isTrue);
      expect(VersionUtils.isBelowMinimum('1.1.0', '1.0.0'), isFalse);
      expect(VersionUtils.isBelowMinimum('1.0.0', '1.0.0'), isFalse);
    });
  });
}
