import 'package:flutter_test/flutter_test.dart';

import 'package:pranidoctor_user/features/farm/data/farm_dto.dart';
import 'package:pranidoctor_user/features/farm/data/farm_validation.dart';
import 'package:pranidoctor_user/features/profile/data/mobile_me_dto.dart';

void main() {
  group('FarmDto', () {
    test('fromProfile returns null without location hierarchy', () {
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

    test('fromProfile builds farm with village id', () {
      const profile = MobileMeDto(
        id: '1',
        name: 'Karim',
        phone: '+8801',
        email: 'k@example.com',
        locale: 'bn-BD',
        role: 'customer',
        area: 'My Farm',
        address: MobileMeAddressDto(
          divisionId: 'd1',
          districtId: 'dist1',
          upazilaId: 'u1',
          unionId: 'un1',
          villageId: 'v1',
        ),
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

    test('FarmInput draft round-trip', () {
      const input = FarmInput(
        name: 'Draft Farm',
        areaLabel: 'Area',
        coverPhotoUrl: 'https://example.com/c.jpg',
        address: MobileMeAddressDto(villageId: 'v1'),
      );
      final restored = FarmInput.fromDraftJson(input.toDraftJson());
      expect(restored.name, 'Draft Farm');
      expect(restored.coverPhotoUrl, 'https://example.com/c.jpg');
      expect(restored.address.villageId, 'v1');
    });
  });

  group('FarmValidation', () {
    test('requires farm name', () {
      expect(
        FarmValidation.validateName('', requiredMessage: 'Required'),
        'Required',
      );
    });

    test('requires location hierarchy for save', () {
      expect(
        FarmValidation.validateLocation(
          const MobileMeAddressDto(villageId: 'v1'),
          hierarchyMessage: 'Required',
        ),
        'Required',
      );
      expect(
        FarmValidation.validateLocation(
          const MobileMeAddressDto(
            divisionId: 'd1',
            districtId: 'dist1',
            upazilaId: 'u1',
            unionId: 'un1',
            villageId: 'v1',
          ),
          hierarchyMessage: 'Required',
        ),
        isNull,
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

  group('FarmSort', () {
    test('sort enum values exist', () {
      expect(FarmSort.values.length, 3);
    });
  });
}
