import 'package:flutter_test/flutter_test.dart';

import 'package:pranidoctor_user/features/profile/data/mobile_me_dto.dart';
import 'package:pranidoctor_user/features/profile/data/profile_media_models.dart';
import 'package:pranidoctor_user/features/profile/data/profile_validation.dart';
import 'package:pranidoctor_user/features/profile/presentation/profile_navigation.dart';
import 'package:pranidoctor_user/routing/app_routes.dart';

void main() {
  group('ProfileValidation', () {
    test('rejects empty name', () {
      expect(
        ProfileValidation.validateName(
          '',
          requiredMessage: 'Required',
          tooLongMessage: 'Too long',
        ),
        'Required',
      );
    });

    test('accepts valid email', () {
      expect(
        ProfileValidation.validateEmail(
          'user@example.com',
          invalidMessage: 'Invalid',
          tooLongMessage: 'Too long',
        ),
        isNull,
      );
    });

    test('rejects invalid email', () {
      expect(
        ProfileValidation.validateEmail(
          'not-an-email',
          invalidMessage: 'Invalid',
          tooLongMessage: 'Too long',
        ),
        isNotNull,
      );
    });

    test('supports backend locale tags', () {
      expect(ProfileValidation.isSupportedLocale('bn-BD'), isTrue);
      expect(ProfileValidation.isSupportedLocale('en-US'), isTrue);
      expect(ProfileValidation.isSupportedLocale('fr-FR'), isFalse);
    });
  });

  group('MobileMeDto setup helpers', () {
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
      const cached = MobileMeAddressDto(
        unionId: 'u1',
        villageId: 'v1',
        divisionId: 'd1',
      );
      final merged = profile.mergeAddress(cached);
      expect(merged.address?.unionId, 'u1');
      expect(merged.hasRequiredLocation, isTrue);
    });

    test('hasRequiredLocation requires unionId', () {
      const withUnion = MobileMeDto(
        id: '1',
        name: 'Test',
        phone: '+8801',
        email: '',
        locale: 'bn-BD',
        role: 'customer',
        address: MobileMeAddressDto(unionId: 'u1'),
      );
      expect(withUnion.hasRequiredLocation, isTrue);
      expect(withUnion.canContinueToHome, isTrue);

      const areaOnly = MobileMeDto(
        id: '1',
        name: 'Test',
        phone: '+8801',
        email: '',
        locale: 'bn-BD',
        role: 'customer',
        area: 'Dhaka Division',
      );
      expect(areaOnly.hasRequiredLocation, isFalse);
      expect(areaOnly.canContinueToHome, isFalse);
    });

    test('canContinueToHome ignores profile photo', () {
      const profile = MobileMeDto(
        id: '1',
        name: 'Test',
        phone: '+8801',
        email: '',
        locale: 'bn-BD',
        role: 'customer',
        profileComplete: false,
        address: MobileMeAddressDto(unionId: 'u1'),
      );
      expect(profile.canContinueToHome, isTrue);
    });

    test('parses avatarUrl and coverUrl aliases from API JSON', () {
      final profile = MobileMeDto.fromJson({
        'id': '1',
        'name': 'Bala G 22',
        'phone': '+8801',
        'email': '',
        'locale': 'bn-BD',
        'role': 'customer',
        'avatarUrl': 'https://cdn.example/a.webp',
        'avatarThumbUrl': 'https://cdn.example/a-thumb.webp',
        'coverUrl': 'https://cdn.example/c.webp',
        'coverThumbUrl': 'https://cdn.example/c-thumb.webp',
      });
      expect(profile.profilePhotoUrl, 'https://cdn.example/a.webp');
      expect(profile.coverPhotoUrl, 'https://cdn.example/c.webp');
    });

    test('parses thumb URL aliases from API JSON', () {
      final profile = MobileMeDto.fromJson({
        'id': '1',
        'name': 'Test',
        'phone': '+8801',
        'email': '',
        'locale': 'bn-BD',
        'role': 'customer',
        'profileImageUrl': 'https://cdn.example/profile.webp',
        'profileImageThumbUrl': 'https://cdn.example/profile-thumb.webp',
        'coverImageUrl': 'https://cdn.example/cover.webp',
        'coverImageThumbUrl': 'https://cdn.example/cover-thumb.webp',
      });
      expect(profile.profilePhotoUrl, 'https://cdn.example/profile.webp');
      expect(
        profile.profilePhotoThumbUrl,
        'https://cdn.example/profile-thumb.webp',
      );
      expect(profile.profileImageUrl, 'https://cdn.example/profile-thumb.webp');
      expect(profile.coverImageUrl, 'https://cdn.example/cover-thumb.webp');
    });

    test('ProfileMediaUploadResult parses avatarUrl contract', () {
      final result = ProfileMediaUploadResult.fromJson({
        'avatarUrl': 'https://cdn.example/a.webp',
        'avatarThumbUrl': 'https://cdn.example/a-thumb.webp',
        'coverUrl': 'https://cdn.example/c.webp',
        'coverThumbUrl': 'https://cdn.example/c-thumb.webp',
      });
      expect(result.avatarUrl, 'https://cdn.example/a.webp');
      expect(result.profileImageUrl, 'https://cdn.example/a-thumb.webp');
      expect(result.coverUrl, 'https://cdn.example/c.webp');
    });

    test('PatchMobileMeInput excludes media fields', () {
      const input = PatchMobileMeInput(
        name: 'Updated',
        email: 'user@example.com',
      );
      final json = input.toJson();
      expect(json.containsKey('profile_image'), isFalse);
      expect(json.containsKey('avatarFileId'), isFalse);
      expect(json.containsKey('coverFileId'), isFalse);
      expect(json['name'], 'Updated');
    });
  });

  group('profileSetupRoute', () {
    test('routes incomplete users to completion screen', () {
      const profile = MobileMeDto(
        id: '1',
        name: 'Test',
        phone: '+8801',
        email: '',
        locale: 'bn-BD',
        role: 'customer',
      );
      expect(profileSetupRoute(profile), AppRoutes.settingsProfileComplete);
    });

    test('routes complete users to home when name and union present', () {
      const profile = MobileMeDto(
        id: '1',
        name: 'Test',
        phone: '+8801',
        email: '',
        locale: 'bn-BD',
        role: 'customer',
        profileComplete: false,
        address: MobileMeAddressDto(unionId: 'u1'),
      );
      expect(profileSetupRoute(profile), AppRoutes.home);
    });
  });
}
