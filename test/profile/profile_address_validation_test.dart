import 'package:flutter_test/flutter_test.dart';

import 'package:pranidoctor_user/features/area/data/area_validation.dart';
import 'package:pranidoctor_user/features/profile/data/mobile_me_dto.dart';

void main() {
  group('Profile address save payload', () {
    test('save without village — union only', () {
      const address = MobileMeAddressDto(
        divisionId: 'div1',
        districtId: 'dist1',
        upazilaId: 'up1',
        unionId: 'un1',
      );

      expect(
        AreaValidation.validateRequiredHierarchy(
          divisionId: address.divisionId,
          districtId: address.districtId,
          upazilaId: address.upazilaId,
          unionId: address.unionId,
          message: 'Required',
        ),
        isNull,
      );

      final json = address.toPatchJson();
      expect(json['unionId'], 'un1');
      expect(json.containsKey('villageId'), isFalse);
      expect(json.containsKey('villageName'), isFalse);
    });

    test('save with catalog village id', () {
      const address = MobileMeAddressDto(
        divisionId: 'div1',
        districtId: 'dist1',
        upazilaId: 'up1',
        unionId: 'un1',
        villageId: 'vil1',
      );

      final json = address.toPatchJson();
      expect(json['villageId'], 'vil1');
      expect(json.containsKey('villageName'), isFalse);
    });

    test('save with custom typed village name', () {
      const address = MobileMeAddressDto(
        divisionId: 'div1',
        districtId: 'dist1',
        upazilaId: 'up1',
        unionId: 'un1',
        villageName: 'Custom Para',
      );

      final json = address.toPatchJson();
      expect(json['villageName'], 'Custom Para');
      expect(json.containsKey('villageId'), isFalse);
    });

    test('union with empty villages still valid for hierarchy', () {
      expect(
        AreaValidation.validateRequiredHierarchy(
          divisionId: 'div1',
          districtId: 'dist1',
          upazilaId: 'up1',
          unionId: 'un-empty',
          message: 'Required',
        ),
        isNull,
      );
      expect(
        AreaValidation.isValidParentChain(
          divisionId: 'div1',
          districtId: 'dist1',
          upazilaId: 'up1',
          unionId: 'un-empty',
          villageId: null,
        ),
        isTrue,
      );
    });

    test('invalid when union missing', () {
      expect(
        AreaValidation.validateRequiredHierarchy(
          divisionId: 'div1',
          districtId: 'dist1',
          upazilaId: 'up1',
          unionId: null,
          message: 'Required',
        ),
        'Required',
      );
    });
  });
}
