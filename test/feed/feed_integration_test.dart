import 'package:flutter_test/flutter_test.dart';

import 'package:pranidoctor_user/features/feed/data/feed_dto.dart';
import 'package:pranidoctor_user/features/feed/data/feed_validation.dart';

void main() {
  group('FeedRecord', () {
    test('parses json', () {
      final record = FeedRecord.fromJson({
        'id': 'f1',
        'customerId': 'c1',
        'animalId': 'a1',
        'animalName': 'Cow',
        'feedType': 'GRASS',
        'amount': '12.5',
        'unit': 'KG',
        'costBdt': '150.00',
        'recordedDate': '2026-05-22',
        'createdAt': '2026-05-22T08:00:00.000Z',
        'updatedAt': '2026-05-22T08:00:00.000Z',
      });
      expect(record.feedType, FeedType.grass);
      expect(record.amount, 12.5);
      expect(record.costBdt, 150);
    });
  });

  group('FeedInput', () {
    test('create json includes target fields', () {
      final input = FeedInput(
        farmRef: 'farm-1',
        animalId: 'a1',
        feedType: FeedType.concentrate,
        amount: 5,
        unit: FeedUnit.kg,
        costBdt: 200,
        recordedDate: DateTime.utc(2026, 5, 22),
      );
      final json = input.toCreateJson();
      expect(json['feedType'], 'CONCENTRATE');
      expect(json['costBdt'], 200);
    });

    test('draft round trip', () {
      final input = FeedInput(
        batchId: 'b1',
        batchName: 'Goat group',
        feedType: FeedType.straw,
        amount: 3,
        unit: FeedUnit.bundle,
        recordedDate: DateTime.utc(2026, 5, 22),
        target: FeedTarget.group,
      );
      final restored = FeedInput.fromDraftJson(input.toDraftJson());
      expect(restored.batchId, 'b1');
      expect(restored.target, FeedTarget.group);
    });
  });

  group('FeedCostData', () {
    test('parses cost payload', () {
      final cost = FeedCostData.fromJson({
        'from': '2026-05-01',
        'to': '2026-05-22',
        'totalCostBdt': 5000,
        'totalAmount': 120,
        'daily': [
          {'date': '2026-05-22', 'costBdt': 200, 'amount': 10},
        ],
        'weekly': [],
        'monthly': [],
        'byAnimal': [
          {'animalId': 'a1', 'animalName': 'Cow', 'costBdt': 200, 'amount': 10},
        ],
      });
      expect(cost.totalCostBdt, 5000);
      expect(cost.byAnimal.single.animalName, 'Cow');
    });
  });

  group('FeedValidation', () {
    test('validates amount and target', () {
      expect(
        FeedValidation.validateAmount('', message: 'Required'),
        'Required',
      );
      expect(
        FeedValidation.validateTarget(
          target: FeedTarget.animal,
          animalId: null,
          batchId: null,
          message: 'Required',
        ),
        'Required',
      );
    });
  });

  group('FeedTargetFilter', () {
    test('enum values for client filtering', () {
      expect(FeedTargetFilter.values.length, 3);
    });
  });

  group('FeedPageResult', () {
    test('copyWith preserves pending sync count', () {
      const page = FeedPageResult(
        records: [],
        total: 0,
        page: 1,
        limit: 20,
        hasMore: false,
        pendingSyncCount: 1,
      );
      expect(page.copyWith(fromCache: true).pendingSyncCount, 1);
    });
  });
}
