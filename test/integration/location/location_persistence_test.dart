import 'package:flutter_test/flutter_test.dart';
import 'package:pranidoctor_user/features/farm/data/farm_dto.dart';
import 'package:pranidoctor_user/features/farm/data/farm_location.dart';
import 'package:pranidoctor_user/features/profile/data/mobile_me_dto.dart';
import 'package:pranidoctor_user/features/profile/presentation/profile_location_draft_provider.dart';

void main() {
  group('user_location_save_restore', () {
    test('mergeAddress keeps village from cache when GET omits it', () {
      const profile = MobileMeDto(
        id: '1',
        name: 'Farmer',
        phone: '+8801',
        email: '',
        locale: 'bn-BD',
        role: 'customer',
        address: MobileMeAddressDto(unionId: 'u1'),
      );
      const cached = MobileMeAddressDto(
        unionId: 'u1',
        villageName: 'Custom Village',
        divisionId: 'd1',
        districtId: 'dist1',
        upazilaId: 'up1',
      );
      final merged = profile.mergeAddress(cached);
      expect(merged.address?.villageName, 'Custom Village');
      expect(merged.address?.divisionId, 'd1');
      expect(merged.hasRequiredLocation, isTrue);
    });

    test('mergeForPatch does not clear hierarchy on partial patch', () {
      const existing = MobileMeAddressDto(
        divisionId: 'd1',
        districtId: 'dist1',
        upazilaId: 'up1',
        unionId: 'u1',
        villageName: 'Old Village',
      );
      const patch = MobileMeAddressDto(
        unionId: 'u1',
        villageName: 'New Village',
      );
      final merged = patch.mergeForPatch(existing);
      expect(merged.divisionId, 'd1');
      expect(merged.districtId, 'dist1');
      expect(merged.upazilaId, 'up1');
      expect(merged.villageName, 'New Village');
    });
  });

  group('farm_location_save_restore', () {
    test('toPatchInput preserves existing area and does not use farm name', () {
      const existing = MobileMeDto(
        id: '1',
        name: 'My Farm Name',
        phone: '+8801',
        email: '',
        locale: 'bn-BD',
        role: 'customer',
        area: 'Saved Area Label',
        address: MobileMeAddressDto(
          divisionId: 'd1',
          districtId: 'dist1',
          upazilaId: 'up1',
          unionId: 'u1',
        ),
      );
      const input = FarmInput(
        name: 'My Farm Name',
        areaLabel: null,
        address: MobileMeAddressDto(unionId: 'u1'),
      );
      final patch = input.toPatchInput(existingProfile: existing);
      expect(patch.area, 'Saved Area Label');
      expect(patch.address?.divisionId, 'd1');
    });

    test('FarmLocation.mergeWith fills gaps from draft', () {
      const profileLoc = FarmLocation(unionId: 'u1');
      const draftLoc = FarmLocation(
        divisionId: 'd1',
        districtId: 'dist1',
        upazilaId: 'up1',
        unionId: 'u1',
        villageName: 'Draft Village',
      );
      final merged = profileLoc.mergeWith(draftLoc);
      expect(merged.hasHierarchy, isTrue);
      expect(merged.villageName, 'Draft Village');
    });
  });

  group('village_persist', () {
    test('empty village in patch keeps existing villageName', () {
      const existing = MobileMeAddressDto(
        unionId: 'u1',
        villageName: 'Keep Me',
      );
      const patch = MobileMeAddressDto(unionId: 'u1');
      final merged = patch.mergeForPatch(existing);
      expect(merged.villageName, 'Keep Me');
    });

    test('custom village persists in toPatchJson', () {
      const address = MobileMeAddressDto(
        unionId: 'u1',
        villageName: '  Custom Hamlet  ',
      );
      final json = address.toPatchJson();
      expect(json['villageName'], 'Custom Hamlet');
    });
  });

  group('profile_completion_refresh', () {
    test('canContinueToHome requires name and union only', () {
      const complete = MobileMeDto(
        id: '1',
        name: 'Test',
        phone: '+8801',
        email: '',
        locale: 'bn-BD',
        role: 'customer',
        profileComplete: false,
        address: MobileMeAddressDto(unionId: 'u1'),
      );
      expect(complete.canContinueToHome, isTrue);

      const noUnion = MobileMeDto(
        id: '1',
        name: 'Test',
        phone: '+8801',
        email: '',
        locale: 'bn-BD',
        role: 'customer',
        address: MobileMeAddressDto(villageName: 'Only Village'),
      );
      expect(noUnion.canContinueToHome, isFalse);
    });
  });

  group('draft_merge', () {
    test('hydrate merge keeps draft village when server omits it', () {
      const server = ProfileLocationDraft(
        unionId: 'u1',
        divisionId: 'd1',
        districtId: 'dist1',
        upazilaId: 'up1',
      );
      const draft = ProfileLocationDraft(
        unionId: 'u1',
        villageName: 'Local Village',
      );
      final merged = server.mergePreserving(draft);
      expect(merged.villageName, 'Local Village');
      expect(merged.divisionId, 'd1');
    });
  });

  group('edit_prefill', () {
    test('Farm.fromProfile includes village in locationLabel', () {
      const profile = MobileMeDto(
        id: '1',
        name: 'Farm',
        phone: '+8801',
        email: '',
        locale: 'bn-BD',
        role: 'customer',
        area: 'Union Area',
        address: MobileMeAddressDto(
          divisionId: 'd1',
          districtId: 'dist1',
          upazilaId: 'up1',
          unionId: 'u1',
          villageName: 'Village X',
        ),
      );
      final farm = Farm.fromProfile(profile: profile);
      expect(farm, isNotNull);
      expect(farm!.locationLabel, contains('Village X'));
    });
  });

  group('offline_restore', () {
    test('mergeFromCache preserves cached optional fields', () {
      const server = MobileMeAddressDto(unionId: 'u1');
      const cached = MobileMeAddressDto(
        unionId: 'u1',
        villageId: 'v1',
        villageName: 'Cached Village',
      );
      final merged = server.mergeFromCache(cached);
      expect(merged.villageId, 'v1');
      expect(merged.villageName, 'Cached Village');
    });
  });

  group('app_restart_restore', () {
    test('ProfileLocationDraft round-trips village through JSON', () {
      const draft = ProfileLocationDraft(
        divisionId: 'd1',
        districtId: 'dist1',
        upazilaId: 'up1',
        unionId: 'u1',
        villageName: 'Persisted',
      );
      final restored = ProfileLocationDraft.fromJson(draft.toJson());
      expect(restored.villageName, 'Persisted');
      expect(restored.hasUnion, isTrue);
    });
  });
}
