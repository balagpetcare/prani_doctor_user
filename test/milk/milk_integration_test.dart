import 'package:flutter_test/flutter_test.dart';

import 'package:pranidoctor_user/features/milk/data/milk_dto.dart';
import 'package:pranidoctor_user/features/milk/data/milk_validation.dart';

void main() {
  group('MilkRecord', () {
    test('parses json', () {
      final record = MilkRecord.fromJson({
        'id': 'm1',
        'customerId': 'c1',
        'animalId': 'a1',
        'animalName': 'Lalu',
        'farmRef': 'farm-1',
        'recordedDate': '2026-05-22',
        'session': 'MORNING',
        'quantityLiters': '12.5',
        'notes': 'Good yield',
        'createdAt': '2026-05-22T06:00:00.000Z',
        'updatedAt': '2026-05-22T06:00:00.000Z',
      });
      expect(record.animalName, 'Lalu');
      expect(record.session, MilkSession.morning);
      expect(record.quantityLiters, 12.5);
    });

    test('round trips json', () {
      final record = MilkRecord(
        id: 'm1',
        customerId: 'c1',
        animalId: 'a1',
        animalName: 'Cow',
        recordedDate: DateTime.utc(2026, 5, 22),
        session: MilkSession.evening,
        quantityLiters: 8,
        createdAt: DateTime.utc(2026, 5, 22),
        updatedAt: DateTime.utc(2026, 5, 22),
      );
      final restored = MilkRecord.fromJson(record.toJson());
      expect(restored.session, MilkSession.evening);
    });
  });

  group('MilkInput', () {
    test('create json uses api session', () {
      final input = MilkInput(
        animalId: 'a1',
        farmRef: 'farm-1',
        recordedDate: DateTime.utc(2026, 5, 22),
        session: MilkSession.morning,
        quantityLiters: 10,
      );
      expect(input.toCreateJson()['session'], 'MORNING');
    });

    test('draft round trip', () {
      final input = MilkInput(
        animalId: 'a1',
        recordedDate: DateTime.utc(2026, 5, 22),
        session: MilkSession.evening,
        quantityLiters: 7.5,
        notes: 'Evening',
      );
      final restored = MilkInput.fromDraftJson(input.toDraftJson());
      expect(restored.notes, 'Evening');
    });
  });

  group('MilkSummary', () {
    test('parses aggregation payload', () {
      final summary = MilkSummary.fromJson({
        'from': '2026-05-15',
        'to': '2026-05-22',
        'totalLiters': 47,
        'morningLiters': 25,
        'eveningLiters': 22,
        'byAnimal': [
          {
            'animalId': 'a1',
            'animalName': 'Lalu',
            'totalLiters': 12,
            'morningLiters': 6,
            'eveningLiters': 6,
          },
        ],
        'byDay': [
          {
            'date': '2026-05-22',
            'totalLiters': 47,
            'morningLiters': 25,
            'eveningLiters': 22,
          },
        ],
      });
      expect(summary.byAnimal.single.animalName, 'Lalu');
      expect(summary.byDay.single.totalLiters, 47);
    });
  });

  group('MilkValidation', () {
    test('validates quantity', () {
      expect(
        MilkValidation.validateQuantity('', message: 'Required'),
        'Required',
      );
      expect(
        MilkValidation.validateQuantity('12.5', message: 'Required'),
        isNull,
      );
    });

    test('validates future date', () {
      final future = DateTime.now().add(const Duration(days: 2));
      expect(
        MilkValidation.validateDate(future, message: 'Invalid'),
        'Invalid',
      );
    });
  });

  group('MilkSessionFilter', () {
    test('enum values exist for client filtering', () {
      expect(MilkSessionFilter.values.length, 3);
      expect(MilkSessionFilter.morning.name, 'morning');
    });
  });

  group('MilkPageResult', () {
    test('copyWith preserves pending sync count', () {
      const page = MilkPageResult(
        records: [],
        total: 0,
        page: 1,
        limit: 20,
        hasMore: false,
        pendingSyncCount: 2,
      );
      expect(page.copyWith(fromCache: true).pendingSyncCount, 2);
    });
  });
}
