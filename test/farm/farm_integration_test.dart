import 'package:flutter_test/flutter_test.dart';

import 'package:pranidoctor_user/features/farm/data/farm_dto.dart';
import 'package:pranidoctor_user/features/farm/data/farm_validation.dart';
import 'package:pranidoctor_user/features/profile/data/mobile_me_dto.dart';

void main() {
  group('FarmDto', () {
    test('fromProfile returns null without village', () {
      const profile = MobileMeDto(
        id: '1',
        name: 'Karim',
        phone: '+8801',
        email: 'k@example.com',
        locale: 'bn-BD',
        role: 'customer',
      );
      expect(Farm.fromProfile(profile: profile), isNull);
    });

    test('fromProfile builds farm with summary counts', () {
      const profile = MobileMeDto(
        id: '1',
        name: 'Karim',
        phone: '+8801',
        email: 'k@example.com',
        locale: 'bn-BD',
        role: 'customer',
        area: 'My Farm',
        address: MobileMeAddressDto(villageId: 'v1'),
      );
      final farm = Farm.fromProfile(
        profile: profile,
        animalCount: 4,
        activeAnimalCount: 3,
        villageLabel: 'Test Village',
      );
      expect(farm?.id, 'farm-v1');
      expect(farm?.animalCount, 4);
      expect(farm?.name, 'My Farm');
    });

    test('round-trips json', () {
      const farm = Farm(
        id: 'farm-v1',
        name: 'Farm',
        locationLabel: 'Village',
        villageId: 'v1',
        animalCount: 2,
        activeAnimalCount: 1,
      );
      final restored = Farm.fromJson(farm.toJson());
      expect(restored.id, 'farm-v1');
      expect(restored.animalCount, 2);
    });
  });

  group('FarmValidation', () {
    test('requires farm name', () {
      expect(
        FarmValidation.validateName('', requiredMessage: 'Required'),
        'Required',
      );
    });

    test('requires village id', () {
      expect(
        FarmValidation.validateVillage(null, requiredMessage: 'Required'),
        'Required',
      );
    });
  });

  group('FarmAnimalSummary', () {
    test('parses animal json', () {
      final animal = FarmAnimalSummary.fromJson({
        'id': 'a1',
        'name': 'Bella',
        'animalType': 'CATTLE',
        'photoUrl': 'https://example.com/a.jpg',
      });
      expect(animal.name, 'Bella');
      expect(animal.animalType, 'CATTLE');
    });
  });
}
