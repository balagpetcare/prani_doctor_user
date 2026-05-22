import 'package:flutter_test/flutter_test.dart';

import 'package:pranidoctor_user/features/vaccine/data/vaccine_dto.dart';
import 'package:pranidoctor_user/features/vaccine/data/vaccine_validation.dart';

void main() {
  group('VaccineRecord', () {
    test('parses json', () {
      final record = VaccineRecord.fromJson({
        'id': 'v1',
        'customerId': 'c1',
        'animalId': 'a1',
        'animalName': 'Cow',
        'vaccineName': 'FMD',
        'scheduledDate': '2026-05-22',
        'status': 'DUE',
        'createdAt': '2026-05-22T08:00:00.000Z',
        'updatedAt': '2026-05-22T08:00:00.000Z',
      });
      expect(record.vaccineName, 'FMD');
      expect(record.status, VaccineStatus.due);
    });
  });

  group('VaccineInput', () {
    test('create json includes vaccine name', () {
      final input = VaccineInput(
        animalId: 'a1',
        vaccineName: 'Anthrax',
        scheduledDate: DateTime.utc(2026, 5, 22),
      );
      final json = input.toCreateJson();
      expect(json['vaccineName'], 'Anthrax');
    });

    test('draft round trip', () {
      final input = VaccineInput(
        animalId: 'a1',
        vaccineName: 'HS',
        vaccineType: 'Booster',
        scheduledDate: DateTime.utc(2026, 5, 22),
      );
      final restored = VaccineInput.fromDraftJson(input.toDraftJson());
      expect(restored.vaccineType, 'Booster');
    });
  });

  group('VaccineValidation', () {
    test('validates name and animal', () {
      expect(VaccineValidation.validateName('', message: 'Required'), 'Required');
      expect(VaccineValidation.validateAnimal(null, message: 'Required'), 'Required');
    });
  });
}
