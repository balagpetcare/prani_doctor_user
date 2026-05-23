import 'package:flutter_test/flutter_test.dart';

import 'package:pranidoctor_user/core/area/area_dto.dart';
import 'package:pranidoctor_user/core/area/area_entities.dart';
import 'package:pranidoctor_user/core/area/area_locale.dart';
import 'package:pranidoctor_user/features/area/data/area_memory_cache.dart';
import 'package:pranidoctor_user/features/area/data/area_validation.dart';
import 'package:pranidoctor_user/features/area/presentation/area_providers.dart';

void main() {
  group('AreaLocale', () {
    test('maps profile bn-BD to bn', () {
      expect(AreaLocale.fromProfileTag('bn-BD'), 'bn');
    });

    test('maps profile en-US to en', () {
      expect(AreaLocale.fromProfileTag('en-US'), 'en');
    });
  });

  group('AreaMemoryCache', () {
    test('deduplicates in-flight requests', () async {
      final cache = AreaMemoryCache();
      final future = Future<AreaPage<AreaNodeDto>>.value(
        const AreaPage(
          data: [
            AreaNodeDto(
              id: '1',
              slug: 'dhaka',
              code: null,
              nameBn: 'ঢাকা',
              nameEn: 'Dhaka',
              label: 'Dhaka',
              level: 'DIVISION',
              isVerified: true,
            ),
          ],
          meta: AreaPageMeta(total: 1, page: 1, pageSize: 1, hasMore: false),
        ),
      );
      cache.track('divisions:bn', future);
      expect(cache.inFlight('divisions:bn'), same(future));
      await future;
      expect(cache.inFlight('divisions:bn'), isNull);
    });
  });

  group('AreaLevelResult', () {
    test('empty factory marks isEmpty', () {
      expect(AreaLevelResult.empty.isEmpty, isTrue);
    });

    test('tracks fromCache flag', () {
      const result = AreaLevelResult(nodes: [], fromCache: true);
      expect(result.fromCache, isTrue);
    });
  });

  group('AreaValidation', () {
    test('requires division through union for profile address', () {
      expect(
        AreaValidation.validateRequiredHierarchy(
          divisionId: null,
          districtId: 'd1',
          upazilaId: 'u1',
          unionId: 'un1',
          message: 'Required',
        ),
        'Required',
      );
      expect(
        AreaValidation.validateRequiredHierarchy(
          divisionId: 'div1',
          districtId: 'dist1',
          upazilaId: 'up1',
          unionId: 'un1',
          message: 'Required',
        ),
        isNull,
      );
    });

    test('union satisfies location without village', () {
      expect(AreaValidation.hasUnionOrVillage(unionId: 'un1'), isTrue);
      expect(
        AreaValidation.hasUnionOrVillage(villageName: 'Custom Para'),
        isTrue,
      );
      expect(AreaValidation.hasUnionOrVillage(), isFalse);
    });

    test('village is optional (deprecated validator returns null)', () {
      expect(
        AreaValidation.validateVillageSelected(null, message: 'Required'),
        isNull,
      );
    });

    test('validates parent chain consistency', () {
      expect(
        AreaValidation.isValidParentChain(
          divisionId: 'd1',
          districtId: 'dist1',
          upazilaId: 'u1',
          unionId: 'un1',
          villageId: 'v1',
        ),
        isTrue,
      );
      expect(
        AreaValidation.isValidParentChain(divisionId: 'd1', villageId: 'v1'),
        isFalse,
      );
    });
  });

  group('AreaSearchParams', () {
    test('equality uses all scope fields', () {
      const a = AreaSearchParams(query: 'farm', unionId: 'u1');
      const b = AreaSearchParams(query: 'farm', unionId: 'u1');
      const c = AreaSearchParams(query: 'farm', unionId: 'u2');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
