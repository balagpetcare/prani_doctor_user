import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pranidoctor_user/core/util/safe_numeric.dart';
import 'package:pranidoctor_user/features/animals/data/animal_dto.dart';
import 'package:pranidoctor_user/features/home/presentation/widgets/home_card.dart';

void main() {
  group('animal_details_nan_test', () {
    test('safe numeric helpers guard NaN and Infinity', () {
      expect(safeInt(double.nan), 0);
      expect(safeInt(double.infinity), 0);
      expect(safeNullableInt(double.nan), isNull);
      expect(safeNullableDouble(double.infinity), isNull);
      expect(safePercent(1, 0), 0);
      expect(safePercent(double.nan, 10), 0);
      expect(safeCacheDimension(double.infinity, 2), isNull);
      expect(safeCacheDimension(100, double.nan), isNull);
    });

    test('AnimalProfile.fromJson tolerates non-finite age values', () {
      final animal = AnimalProfile.fromJson({
        'id': 'a1',
        'customerId': 'c1',
        'name': 'Bella',
        'species': 'Goat',
        'category': 'LIVESTOCK',
        'ageYears': double.nan,
        'ageMonths': double.infinity,
        'active': true,
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
      });

      expect(animal.ageYears, isNull);
      expect(animal.ageMonths, isNull);
    });

    testWidgets('HomeCachedImage does not crash with infinite dimensions', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 120,
              child: HomeCachedImage(
                url: 'https://example.com/photo.jpg',
                width: double.infinity,
                height: double.infinity,
                fallbackIcon: Icons.pets,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
