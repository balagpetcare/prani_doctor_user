import 'package:flutter_test/flutter_test.dart';
import 'package:pranidoctor_user/features/animals/data/animal_dto.dart';

void main() {
  group('animal_creation_restore_test', () {
    test('blank create draft round-trip is treated as empty', () {
      const input = AnimalInput(animalType: 'GOAT');
      final restored = AnimalInput.fromDraftJson(input.toDraftJson());

      expect(restored.name, isNull);
      expect(restored.tag, isNull);
      expect(restored.animalType, 'GOAT');
    });

    test('meaningful draft round-trip restores user input', () {
      const input = AnimalInput(
        animalType: 'CATTLE',
        name: 'Bella',
        tag: 'T-001',
        breed: 'Local',
        ageYears: 3,
        weightKg: 420,
        notes: 'Healthy',
      );

      final restored = AnimalInput.fromDraftJson(input.toDraftJson());

      expect(restored.name, 'Bella');
      expect(restored.tag, 'T-001');
      expect(restored.breed, 'Local');
      expect(restored.ageYears, 3);
      expect(restored.weightKg, 420);
      expect(restored.notes, 'Healthy');
    });

    test('draft with non-finite numbers does not throw', () {
      final restored = AnimalInput.fromDraftJson({
        'animalType': 'GOAT',
        'ageYears': double.nan,
        'weightKg': double.infinity,
      });

      expect(restored.ageYears, isNull);
      expect(restored.weightKg, isNull);
    });
  });
}
