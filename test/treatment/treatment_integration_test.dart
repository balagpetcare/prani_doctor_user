import 'package:flutter_test/flutter_test.dart';

import 'package:pranidoctor_user/features/treatment/data/treatment_dto.dart';
import 'package:pranidoctor_user/features/treatment/data/treatment_validation.dart';

void main() {
  group('FarmTreatment', () {
    test('parses json with medicines', () {
      final treatment = FarmTreatment.fromJson({
        'id': 't1',
        'customerId': 'c1',
        'animalId': 'a1',
        'animalName': 'Cow',
        'title': 'Antibiotic course',
        'medicines': [
          {'name': 'Oxytetracycline', 'dosage': '10ml', 'frequency': 'Daily', 'durationDays': 5},
        ],
        'startDate': '2026-05-22',
        'status': 'ACTIVE',
        'createdAt': '2026-05-22T08:00:00.000Z',
        'updatedAt': '2026-05-22T08:00:00.000Z',
      });
      expect(treatment.medicines.single.name, 'Oxytetracycline');
      expect(treatment.status, TreatmentStatus.active);
    });
  });

  group('TreatmentInput', () {
    test('create json includes medicines', () {
      final input = TreatmentInput(
        animalId: 'a1',
        title: 'Course',
        medicines: const [MedicineItem(name: 'Med', dosage: '5ml')],
        startDate: DateTime.utc(2026, 5, 22),
      );
      final json = input.toCreateJson();
      expect(json['medicines'], isA<List<dynamic>>());
    });

    test('draft round trip', () {
      final input = TreatmentInput(
        animalId: 'a1',
        title: 'Course',
        startDate: DateTime.utc(2026, 5, 22),
        status: TreatmentStatus.completed,
      );
      final restored = TreatmentInput.fromDraftJson(input.toDraftJson());
      expect(restored.status, TreatmentStatus.completed);
    });
  });

  group('TreatmentValidation', () {
    test('validates medicine fields', () {
      expect(
        TreatmentValidation.validateMedicine(
          const MedicineItem(name: '', dosage: ''),
          message: 'Invalid',
        ),
        'Invalid',
      );
    });
  });
}
