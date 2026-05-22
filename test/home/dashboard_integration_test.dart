import 'package:flutter_test/flutter_test.dart';

import 'package:pranidoctor_user/core/error/app_exception.dart';
import 'package:pranidoctor_user/features/home/data/dashboard_context_dto.dart';
import 'package:pranidoctor_user/features/home/presentation/home_providers.dart';

void main() {
  group('DashboardContextDto', () {
    test('parses farm summary and user', () {
      final ctx = DashboardContext.fromJson({
        'dashboardType': 'GENERAL',
        'user': {
          'id': 'u1',
          'name': 'Rahim',
          'phone': '+8801',
          'email': 'r@example.com',
          'avatarUrl': null,
        },
        'farmSummary': {
          'animalCount': 5,
          'activeAnimalCount': 4,
          'primaryVillageId': 'v1',
          'primaryVillageLabelBn': 'গ্রাম',
        },
      });

      expect(ctx.user.name, 'Rahim');
      expect(ctx.farmSummary?.animalCount, 5);
      expect(ctx.farmSummary?.totalFarms, 1);
    });

    test('totalFarms is zero without primary village', () {
      const summary = FarmSummary(animalCount: 2, activeAnimalCount: 2);
      expect(summary.totalFarms, 0);
    });

    test('round-trips through json', () {
      const original = DashboardContext(
        dashboardType: DashboardType.general,
        user: DashboardContextUser(
          id: '1',
          name: 'Test',
          phone: '+8801',
          email: 't@example.com',
        ),
        farmSummary: FarmSummary(
          animalCount: 1,
          activeAnimalCount: 1,
          primaryVillageId: 'v1',
        ),
      );
      final restored = DashboardContext.fromJson(original.toJson());
      expect(restored.user.id, '1');
      expect(restored.farmSummary?.primaryVillageId, 'v1');
    });
  });

  group('DashboardSummary', () {
    test('empty constant has zero counts', () {
      expect(DashboardSummary.empty.totalAnimals, 0);
      expect(DashboardSummary.empty.activeAppointments, 0);
    });
  });

  group('Dashboard auth helpers', () {
    test('detects unauthorized errors', () {
      expect(
        isDashboardUnauthorized(
          const AppException(message: 'Unauthorized', code: '401'),
        ),
        isTrue,
      );
    });
  });
}
