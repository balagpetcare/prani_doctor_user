import 'package:flutter_test/flutter_test.dart';
import 'package:pranidoctor_user/features/profile/data/mobile_me_dto.dart';
import 'package:pranidoctor_user/features/profile/services/profile_completion_service.dart';

void main() {
  group('ProfileCompletionService', () {
    test('profileCompleted requires name and unionId', () {
      const complete = MobileMeDto(
        id: '1',
        name: 'Rahim',
        phone: '+8801',
        email: '',
        locale: 'bn-BD',
        role: 'customer',
        address: MobileMeAddressDto(unionId: 'u1'),
      );
      expect(
        ProfileCompletionService.evaluate(complete).profileCompleted,
        isTrue,
      );

      const noUnion = MobileMeDto(
        id: '1',
        name: 'Rahim',
        phone: '+8801',
        email: '',
        locale: 'bn-BD',
        role: 'customer',
        area: 'Some Area',
      );
      expect(
        ProfileCompletionService.evaluate(noUnion).profileCompleted,
        isFalse,
      );
    });

    test('village is optional for completion', () {
      const withVillageName = MobileMeDto(
        id: '1',
        name: 'Rahim',
        phone: '+8801',
        email: '',
        locale: 'bn-BD',
        role: 'customer',
        address: MobileMeAddressDto(
          unionId: 'u1',
          villageName: 'Hamlet',
        ),
      );
      final status = ProfileCompletionService.evaluate(withVillageName);
      expect(status.profileCompleted, isTrue);
      expect(status.hasVillage, isTrue);
    });

    test('reconcileWithServer trusts server when cache would inflate completion', () {
      const server = MobileMeDto(
        id: '1',
        name: 'Rahim',
        phone: '+8801',
        email: '',
        locale: 'bn-BD',
        role: 'customer',
      );
      const cached = MobileMeAddressDto(unionId: 'u-stale');
      final reconciled = ProfileCompletionService.reconcileWithServer(
        server: server,
        cachedAddress: cached,
      );
      expect(reconciled.address?.unionId, isNull);
      expect(
        ProfileCompletionService.evaluate(reconciled).profileCompleted,
        isFalse,
      );
    });

    test('reconcileWithServer merges optional village from cache when server has union', () {
      const server = MobileMeDto(
        id: '1',
        name: 'Rahim',
        phone: '+8801',
        email: '',
        locale: 'bn-BD',
        role: 'customer',
        address: MobileMeAddressDto(unionId: 'u1'),
      );
      const cached = MobileMeAddressDto(
        unionId: 'u1',
        villageName: 'Cached Village',
      );
      final reconciled = ProfileCompletionService.reconcileWithServer(
        server: server,
        cachedAddress: cached,
      );
      expect(reconciled.address?.unionId, 'u1');
      expect(reconciled.address?.villageName, 'Cached Village');
      expect(
        ProfileCompletionService.evaluate(reconciled).profileCompleted,
        isTrue,
      );
    });

    test('shouldBypassOnboarding mirrors profileCompleted', () {
      const complete = MobileMeDto(
        id: '1',
        name: 'Rahim',
        phone: '+8801',
        email: '',
        locale: 'bn-BD',
        role: 'customer',
        address: MobileMeAddressDto(unionId: 'u1'),
      );
      expect(ProfileCompletionService.shouldBypassOnboarding(complete), isTrue);
      expect(ProfileCompletionService.shouldBypassOnboarding(null), isFalse);
    });
  });
}
