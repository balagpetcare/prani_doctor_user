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

  group('HealthPageResult', () {
    test('copyWith preserves pending sync count', () {
      const page = HealthPageResult(
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

  group('HealthSummaryData', () {
    test('computes counts from records', () {
      final records = [
        HealthEvent(
          id: '1',
          customerId: 'c1',
          eventType: HealthEventType.disease,
          title: 'A',
          recordedDate: DateTime.utc(2026, 5, 1),
          createdAt: DateTime.utc(2026, 5, 1),
          updatedAt: DateTime.utc(2026, 5, 1),
          pendingSync: true,
        ),
        HealthEvent(
          id: '2',
          customerId: 'c1',
          eventType: HealthEventType.checkup,
          title: 'B',
          recordedDate: DateTime.utc(2026, 5, 2),
          createdAt: DateTime.utc(2026, 5, 2),
          updatedAt: DateTime.utc(2026, 5, 2),
        ),
      ];
      final summary = HealthSummaryData.fromRecords(records, total: 10);
      expect(summary.totalEvents, 10);
      expect(summary.diseaseEvents, 1);
      expect(summary.checkupEvents, 1);
      expect(summary.pendingSyncCount, 1);
    });
  });

  group('HealthAnalyticsData', () {
    test('computes breakdown from records', () {
      final records = [
        HealthEvent(
          id: '1',
          customerId: 'c1',
          eventType: HealthEventType.disease,
          title: 'Mastitis',
          diseaseName: 'Mastitis',
          recordedDate: DateTime.utc(2026, 5, 1),
          createdAt: DateTime.utc(2026, 5, 1),
          updatedAt: DateTime.utc(2026, 5, 1),
        ),
      ];
      final analytics = HealthAnalyticsData.fromRecords(records);
      expect(analytics.diseaseFrequency.single.name, 'Mastitis');
      expect(analytics.eventTypeBreakdown.single.count, 1);
    });
  });

  group('HealthValidation', () {
    test('validates title and date', () {
      expect(
        HealthValidation.validateTitle('', message: 'Required'),
        'Required',
      );
      expect(
        HealthValidation.validateDate(
          DateTime.now().add(const Duration(days: 2)),
          message: 'Invalid',
        ),
        'Invalid',
      );
    });
  });
}
