import 'package:flutter_test/flutter_test.dart';

import 'package:pranidoctor_user/features/farm/data/farm_dto.dart';
import 'package:pranidoctor_user/features/farm/data/farm_location.dart';
import 'package:pranidoctor_user/features/farm/data/farm_validation.dart';
import 'package:pranidoctor_user/features/profile/data/mobile_me_dto.dart';

void main() {
  group('FarmLocation', () {
    test('canSaveFarm requires hierarchy through union', () {
      const location = FarmLocation(
        divisionId: 'd1',
        districtId: 'dist1',
        upazilaId: 'u1',
        unionId: 'un1',
      );
      expect(location.canSaveFarm, isTrue);
      expect(location.hasVillageSelection, isFalse);
    });

    test('custom village saves villageName without villageId', () {
      const location = FarmLocation(
        divisionId: 'd1',
        districtId: 'dist1',
        upazilaId: 'u1',
        unionId: 'un1',
        villageName: 'Custom Village',
        displayAddress: 'Custom Village',
      );
      final dto = location.toAddressDto();
      expect(dto.villageName, 'Custom Village');
      expect(dto.villageId, isNull);
      expect(location.canSaveFarm, isTrue);
    });

    test('json round-trip preserves all fields', () {
      const original = FarmLocation(
        divisionId: 'd1',
        districtId: 'dist1',
        upazilaId: 'u1',
        unionId: 'un1',
        villageId: 'v1',
        villageName: 'Test Village',
        displayAddress: 'Test Village',
      );
      final restored = FarmLocation.fromJson(original.toJson());
      expect(restored, original);
    });

    test('farmIdFor prefers village then union', () {
      const withVillage = FarmLocation(
        unionId: 'un1',
        villageId: 'v1',
      );
      expect(withVillage.farmIdFor(), 'farm-v1');

      const unionOnly = FarmLocation(unionId: 'un1');
      expect(unionOnly.farmIdFor(), 'farm-union:un1');
    });
  });

  group('Farm.fromProfile location restore', () {
    test('returns null without union hierarchy', () {
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

    test('builds farm with union only and villageName', () {
      const profile = MobileMeDto(
        id: '1',
        name: 'Karim Farm',
        phone: '+8801',
        email: 'k@example.com',
        locale: 'bn-BD',
        role: 'customer',
        area: 'Custom Village',
        address: MobileMeAddressDto(
          divisionId: 'd1',
          districtId: 'dist1',
          upazilaId: 'u1',
          unionId: 'un1',
          villageName: 'Custom Village',
        ),
      );
      final farm = Farm.fromProfile(profile: profile);
      expect(farm, isNotNull);
      expect(farm!.id, 'farm-union:un1');
      expect(farm.address?.unionId, 'un1');
      expect(farm.address?.villageName, 'Custom Village');
    });

    test('builds farm with villageId', () {
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
      );
      expect(farm?.id, 'farm-v1');
      expect(farm?.animalCount, 4);
    });
  });

  group('FarmValidation', () {
    test('validateLocation requires union hierarchy', () {
      expect(
        FarmValidation.validateLocation(
          const MobileMeAddressDto(unionId: 'un1'),
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
          ),
          hierarchyMessage: 'Required',
        ),
        isNull,
      );
    });

    test('validateLocation allows custom village without villageId', () {
      expect(
        FarmValidation.validateLocation(
          const MobileMeAddressDto(
            divisionId: 'd1',
            districtId: 'dist1',
            upazilaId: 'u1',
            unionId: 'un1',
            villageName: 'Typed Village',
          ),
          hierarchyMessage: 'Required',
        ),
        isNull,
      );
    });
  });

  group('FarmInput draft restore', () {
    test('draft round-trip with location block', () {
      const input = FarmInput(
        name: 'Draft Farm',
        areaLabel: 'Village Label',
        address: MobileMeAddressDto(
          divisionId: 'd1',
          districtId: 'dist1',
          upazilaId: 'u1',
          unionId: 'un1',
          villageId: 'v1',
          villageName: 'Village Label',
        ),
      );
      final restored = FarmInput.fromDraftJson(input.toDraftJson());
      expect(restored.name, 'Draft Farm');
      expect(restored.address.unionId, 'un1');
      expect(restored.address.villageId, 'v1');
      expect(restored.address.villageName, 'Village Label');
    });

    test('draft restores custom village name', () {
      const input = FarmInput(
        name: 'Draft Farm',
        areaLabel: 'Custom',
        address: MobileMeAddressDto(
          divisionId: 'd1',
          districtId: 'dist1',
          upazilaId: 'u1',
          unionId: 'un1',
          villageName: 'Custom',
        ),
      );
      final restored = FarmInput.fromDraftJson(input.toDraftJson());
      expect(restored.address.villageName, 'Custom');
      expect(restored.address.villageId, isNull);
    });
  });
}
