import 'package:flutter_test/flutter_test.dart';

import 'package:pranidoctor_user/features/health/data/health_dto.dart';
import 'package:pranidoctor_user/features/health/data/health_validation.dart';

void main() {
  group('HealthEvent', () {
    test('parses json', () {
      final event = HealthEvent.fromJson({
        'id': 'h1',
        'customerId': 'c1',
        'animalId': 'a1',
        'animalName': 'Cow',
        'eventType': 'SYMPTOM',
        'title': 'Fever',
        'symptoms': 'High temp',
        'recordedDate': '2026-05-22',
        'createdAt': '2026-05-22T08:00:00.000Z',
        'updatedAt': '2026-05-22T08:00:00.000Z',
      });
      expect(event.eventType, HealthEventType.symptom);
      expect(event.title, 'Fever');
    });
  });

  group('HealthInput', () {
    test('create json includes event type', () {
      final input = HealthInput(
        animalId: 'a1',
        eventType: HealthEventType.diagnosis,
        title: 'Test',
        recordedDate: DateTime.utc(2026, 5, 22),
      );
      final json = input.toCreateJson();
      expect(json['eventType'], 'DIAGNOSIS');
      expect(json['title'], 'Test');
    });

    test('draft round trip', () {
      final input = HealthInput(
        animalId: 'a1',
        eventType: HealthEventType.checkup,
        title: 'Routine',
        recordedDate: DateTime.utc(2026, 5, 22),
      );
      final restored = HealthInput.fromDraftJson(input.toDraftJson());
      expect(restored.eventType, HealthEventType.checkup);
    });
  });

  group('HealthTimelineResult', () {
    test('parses timeline payload', () {
      final timeline = HealthTimelineResult.fromJson({
        'groups': [
          {
            'date': '2026-05-22',
            'events': [
              {
                'id': 'h1',
                'eventType': 'DISEASE',
                'title': 'Mastitis',
                'recordedDate': '2026-05-22',
                'createdAt': '2026-05-22T08:00:00.000Z',
                'updatedAt': '2026-05-22T08:00:00.000Z',
              },
            ],
          },
        ],
        'total': 1,
        'page': 1,
        'limit': 20,
        'hasMore': false,
      });
      expect(timeline.groups.single.events.single.title, 'Mastitis');
    });
  });

  group('HealthValidation', () {
    test('validates title and date', () {
      expect(HealthValidation.validateTitle('', message: 'Required'), 'Required');
      expect(
        HealthValidation.validateDate(DateTime.now().add(const Duration(days: 2)), message: 'Invalid'),
        'Invalid',
      );
    });
  });
}
