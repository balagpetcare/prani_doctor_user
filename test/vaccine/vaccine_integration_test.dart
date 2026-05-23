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

  group('VaccinePageResult', () {
    test('copyWith preserves pending sync count', () {
      const page = VaccinePageResult(
        records: [],
        total: 0,
        page: 1,
        limit: 20,
        hasMore: false,
        pendingSyncCount: 2,
      );
      expect(page.copyWith(total: 5).pendingSyncCount, 2);
    });
  });

  group('VaccineSummaryData', () {
    test('computes summary from records and reminders', () {
      final records = [
        VaccineRecord(
          id: '1',
          customerId: 'c1',
          vaccineName: 'FMD',
          scheduledDate: DateTime.utc(2026, 5, 1),
          status: VaccineStatus.completed,
          createdAt: DateTime.utc(2026, 5, 1),
          updatedAt: DateTime.utc(2026, 5, 1),
        ),
      ];
      final reminders = VaccineRemindersData(
        overdue: [
          VaccineRecord(
            id: '2',
            customerId: 'c1',
            vaccineName: 'HS',
            scheduledDate: DateTime.utc(2026, 5, 10),
            status: VaccineStatus.overdue,
            createdAt: DateTime.utc(2026, 5, 1),
            updatedAt: DateTime.utc(2026, 5, 1),
          ),
        ],
        upcoming: [
          VaccineRecord(
            id: '3',
            customerId: 'c1',
            vaccineName: 'BQ',
            scheduledDate: DateTime.utc(2026, 6, 1),
            status: VaccineStatus.due,
            createdAt: DateTime.utc(2026, 5, 1),
            updatedAt: DateTime.utc(2026, 5, 1),
          ),
        ],
      );
      final summary = VaccineSummaryData.fromSources(
        allRecords: records,
        reminders: reminders,
      );
      expect(summary.completed, 1);
      expect(summary.overdue, 1);
      expect(summary.upcoming, 1);
    });
  });

  group('VaccineValidation', () {
    test('validates name and animal', () {
      expect(
        VaccineValidation.validateName('', message: 'Required'),
        'Required',
      );
      expect(
        VaccineValidation.validateAnimal(null, message: 'Required'),
        'Required',
      );
    });
  });
}
