import 'package:flutter_test/flutter_test.dart';

import 'package:pranidoctor_user/features/animals/data/animal_dto.dart';
import 'package:pranidoctor_user/features/animals/data/animal_validation.dart';

void main() {
  group('AnimalProfile', () {
    test('parses full json', () {
      final animal = AnimalProfile.fromJson({
        'id': 'a1',
        'customerId': 'c1',
        'name': 'Bella',
        'species': 'Cattle',
        'category': 'LIVESTOCK',
        'animalType': 'CATTLE',
        'breed': 'Local',
        'weightKg': '450',
        'microchipOrTag': 'T-001',
        'active': true,
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-02T00:00:00.000Z',
      });
      expect(animal.name, 'Bella');
      expect(animal.displayTag, 'T-001');
      expect(animal.weightKg, '450');
    });

    test('round-trips json', () {
      final animal = AnimalProfile(
        id: 'a1',
        customerId: 'c1',
        name: 'Goat',
        species: 'Goat',
        category: 'LIVESTOCK',
        animalType: 'GOAT',
        active: true,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      final restored = AnimalProfile.fromJson(animal.toJson());
      expect(restored.id, 'a1');
    });
  });

  group('AnimalInput', () {
    test('create json requires type', () {
      const input = AnimalInput(animalType: 'GOAT', name: 'Mini', tag: 'G1');
      final json = input.toCreateJson();
      expect(json['animalType'], 'GOAT');
      expect(json['name'], 'Mini');
      expect(json['tag'], 'G1');
    });

    test('draft round trip', () {
      const input = AnimalInput(
        animalType: 'CATTLE',
        name: 'Cow',
        breed: 'Sahiwal',
        weightKg: 400,
      );
      final restored = AnimalInput.fromDraftJson(input.toDraftJson());
      expect(restored.breed, 'Sahiwal');
      expect(restored.weightKg, 400);
    });
  });

  group('AnimalValidation', () {
    test('requires name or tag', () {
      expect(
        AnimalValidation.validateNameOrTag(
          name: '',
          tag: '',
          message: 'Required',
        ),
        'Required',
      );
    });

    test('validates weight', () {
      expect(AnimalValidation.validateWeight('abc'), isNotNull);
      expect(AnimalValidation.validateWeight('120'), isNull);
    });
  });

  group('AnimalSort', () {
    test('has expected values', () {
      expect(AnimalSort.values.length, 4);
    });
  });

  group('AnimalPageResult', () {
    test('includes summary counts', () {
      const page = AnimalPageResult(
        animals: [],
        total: 5,
        page: 1,
        pageSize: 20,
        hasMore: false,
        activeCount: 4,
        inactiveCount: 1,
        livestockCount: 3,
      );
      expect(page.activeCount, 4);
      expect(page.livestockCount, 3);
    });
  });
}
