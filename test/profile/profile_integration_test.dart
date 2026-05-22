import 'package:flutter_test/flutter_test.dart';

import 'package:pranidoctor_user/features/profile/data/mobile_me_dto.dart';
import 'package:pranidoctor_user/features/profile/data/profile_validation.dart';

void main() {
  group('ProfileValidation', () {
    test('rejects empty name', () {
      expect(
        ProfileValidation.validateName('', requiredMessage: 'Required'),
        'Required',
      );
    });

    test('accepts valid email', () {
      expect(ProfileValidation.validateEmail('user@example.com'), isNull);
    });

    test('rejects invalid email', () {
      expect(ProfileValidation.validateEmail('not-an-email'), isNotNull);
    });

    test('supports backend locale tags', () {
      expect(ProfileValidation.isSupportedLocale('bn-BD'), isTrue);
      expect(ProfileValidation.isSupportedLocale('en-US'), isTrue);
      expect(ProfileValidation.isSupportedLocale('fr-FR'), isFalse);
    });
  });

  group('MobileMeDto cache merge', () {
    test('mergeAddress fills missing GET address from cache', () {
      const profile = MobileMeDto(
        id: '1',
        name: 'Test',
        phone: '+8801',
        email: '',
        locale: 'bn-BD',
        role: 'customer',
        area: 'Village',
      );
      const cached = MobileMeAddressDto(villageId: 'v1', divisionId: 'd1');
      final merged = profile.mergeAddress(cached);
      expect(merged.address?.villageId, 'v1');
    });
  });
}
