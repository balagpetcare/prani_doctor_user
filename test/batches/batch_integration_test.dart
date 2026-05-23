import 'package:flutter_test/flutter_test.dart';

import 'package:pranidoctor_user/features/batches/data/batch_dto.dart';
import 'package:pranidoctor_user/features/batches/data/batch_validation.dart';

void main() {
  group('AnimalBatch', () {
    test('parses full json', () {
      final batch = AnimalBatch.fromJson({
        'id': 'b1',
        'name': 'Goat pen A',
        'animalType': 'GOAT',
        'animalIds': ['a1', 'a2'],
        'active': true,
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-02T00:00:00.000Z',
        'movements': [
          {
            'id': 'm1',
            'type': 'MOVE',
            'fromBatchId': 'b0',
            'toBatchId': 'b1',
            'animalIds': ['a1'],
            'at': '2026-01-02T00:00:00.000Z',
          },
        ],
      });
      expect(batch.name, 'Goat pen A');
      expect(batch.animalCount, 2);
      expect(batch.movements.single.type, 'MOVE');
    });

    test('round-trips json', () {
      final batch = AnimalBatch(
        id: 'b1',
        name: 'Cattle batch',
        animalType: 'CATTLE',
        animalIds: const ['a1'],
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      final restored = AnimalBatch.fromJson(batch.toJson());
      expect(restored.id, 'b1');
      expect(restored.animalIds, ['a1']);
    });
  });

  group('BatchInput', () {
    test('create json includes animal ids', () {
      const input = BatchInput(
        name: 'Pen 1',
        animalType: 'GOAT',
        animalIds: ['a1'],
      );
      final json = input.toCreateJson();
      expect(json['name'], 'Pen 1');
      expect(json['animalIds'], ['a1']);
    });

    test('draft round trip', () {
      const input = BatchInput(
        name: 'Merged',
        notes: 'North shed',
        location: 'Shed 2',
      );
      final restored = BatchInput.fromDraftJson(input.toDraftJson());
      expect(restored.notes, 'North shed');
      expect(restored.location, 'Shed 2');
    });
  });

  group('BatchValidation', () {
    test('requires batch name', () {
      expect(
        BatchValidation.validateName(' ', message: 'Required'),
        'Required',
      );
      expect(
        BatchValidation.validateName('Pen A', message: 'Required'),
        isNull,
      );
    });

    test('validates move targets', () {
      expect(
        BatchValidation.validateMove(
          fromBatchId: 'b1',
          toBatchId: 'b1',
          animalIds: const ['a1'],
          message: 'Invalid',
        ),
        'Invalid',
      );
      expect(
        BatchValidation.validateMove(
          fromBatchId: 'b1',
          toBatchId: 'b2',
          animalIds: const ['a1'],
          message: 'Invalid',
        ),
        isNull,
      );
    });

    test('validates merge targets', () {
      expect(
        BatchValidation.validateMerge(
          sourceId: 'b1',
          targetId: 'b1',
          message: 'Invalid',
        ),
        'Invalid',
      );
      expect(
        BatchValidation.validateMerge(
          sourceId: 'b1',
          targetId: 'b2',
          message: 'Invalid',
        ),
        isNull,
      );
    });
  });

  group('BatchSort', () {
    test('orders by animal count descending', () {
      final batches = [
        AnimalBatch(
          id: 'b1',
          name: 'Small',
          animalIds: const ['a1'],
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
        AnimalBatch(
          id: 'b2',
          name: 'Large',
          animalIds: const ['a1', 'a2', 'a3'],
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      ];
      final sorted = [...batches]
        ..sort((a, b) => b.animalCount.compareTo(a.animalCount));
      expect(sorted.first.id, 'b2');
    });
  });

  group('BatchPageResult', () {
    test('copyWith preserves summary stats', () {
      const page = BatchPageResult(
        batches: [],
        total: 2,
        page: 1,
        pageSize: 20,
        hasMore: false,
        withAnimalsCount: 1,
        emptyCount: 1,
        pendingSyncCount: 0,
      );
      expect(page.copyWith(fromCache: true).withAnimalsCount, 1);
      expect(page.copyWith(fromCache: true).emptyCount, 1);
    });
  });
}
