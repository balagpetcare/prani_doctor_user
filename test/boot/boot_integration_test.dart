import 'package:flutter_test/flutter_test.dart';

import 'package:pranidoctor_user/core/utils/version_utils.dart';
import 'package:pranidoctor_user/features/app_config/data/app_config_dto.dart';
import 'package:pranidoctor_user/features/boot/boot_state.dart';

void main() {
  group('AppConfigDto', () {
    test('parses maintenance and version fields', () {
      final dto = AppConfigDto.fromJson({
        'supportPhone': '+8809612345678',
        'minimumVersion': '2.0.0',
        'recommendedVersion': '2.1.0',
        'updateUrl':
            'https://play.google.com/store/apps/details?id=com.example',
        'updateRequired': false,
        'maintenanceMode': true,
        'maintenanceMessage': 'Scheduled maintenance',
      });

      expect(dto.minimumVersion, '2.0.0');
      expect(dto.recommendedVersion, '2.1.0');
      expect(dto.isMaintenanceMode, isTrue);
      expect(dto.maintenanceMessage, 'Scheduled maintenance');
    });
  });

  group('VersionUtils', () {
    test('detects below minimum and recommended versions', () {
      expect(VersionUtils.isBelowMinimum('1.0.0', '1.1.0'), isTrue);
      expect(VersionUtils.isBelowMinimum('1.1.0', '1.0.0'), isFalse);
      expect(VersionUtils.isBelowMinimum('2.0.0', '2.0.0'), isFalse);
      expect(VersionUtils.isBelowMinimum('2.0.9', '2.1.0'), isTrue);
    });
  });

  group('BootState', () {
    test('blocked phases prevent ready navigation', () {
      const maintenance = BootState(
        phase: BootPhase.maintenance,
        maintenance: MaintenanceInfo(message: 'Down'),
      );
      const optional = BootState(
        phase: BootPhase.optionalUpdate,
        optionalUpdate: OptionalUpdateInfo(
          recommendedVersion: '2.0.0',
          currentVersion: '1.0.0',
          message: 'Update',
        ),
      );

      expect(maintenance.isBlocked, isTrue);
      expect(maintenance.isReady, isFalse);
      expect(optional.isBlocked, isTrue);
      expect(optional.optionalUpdatePending, isTrue);
    });
  });
}
