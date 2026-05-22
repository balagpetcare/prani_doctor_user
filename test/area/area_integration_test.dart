import 'package:flutter_test/flutter_test.dart';

import 'package:pranidoctor_user/core/area/area_dto.dart';
import 'package:pranidoctor_user/core/area/area_entities.dart';
import 'package:pranidoctor_user/core/area/area_locale.dart';
import 'package:pranidoctor_user/features/area/data/area_memory_cache.dart';

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
        AreaPage(
          data: const [
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
          meta: const AreaPageMeta(total: 1, page: 1, pageSize: 1, hasMore: false),
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
  });
}
