import 'package:flutter_test/flutter_test.dart';

import 'package:pranidoctor_user/features/notifications/data/notification_dto.dart';
import 'package:pranidoctor_user/features/notifications/data/notification_grouping.dart';
import 'package:pranidoctor_user/features/notifications/notification_deeplink.dart';

void main() {
  group('MobileNotificationDto', () {
    test('parses json and unread state', () {
      final dto = MobileNotificationDto.fromJson({
        'id': 'n1',
        'type': 'REQUEST_UPDATE',
        'title': 'Doctor accepted',
        'body': 'Your request was accepted',
        'createdAt': DateTime.now().toIso8601String(),
        'metadata': {'serviceRequestId': 'sr1'},
      });
      expect(dto.isUnread, isTrue);
      expect(dto.serviceRequestId, 'sr1');
    });
  });

  group('NotificationSettingsDto', () {
    test('round trips json', () {
      const settings = NotificationSettingsDto(
        pushEnabled: true,
        marketingEnabled: false,
        treatmentReminderEnabled: true,
        vaccineReminderEnabled: true,
        orderServiceEnabled: false,
        updatedAt: '2026-05-22T00:00:00.000Z',
      );
      final restored = NotificationSettingsDto.fromJson(settings.toJson());
      expect(restored.pushEnabled, isTrue);
      expect(restored.orderServiceEnabled, isFalse);
    });
  });

  group('NotificationGrouping', () {
    test('groups items by date', () {
      final now = DateTime.now();
      final items = [
        MobileNotificationDto(
          id: '1',
          type: 'SYSTEM',
          title: 'Today',
          body: 'Body',
          createdAt: now.toIso8601String(),
        ),
        MobileNotificationDto(
          id: '2',
          type: 'SYSTEM',
          title: 'Earlier',
          body: 'Body',
          createdAt: now.subtract(const Duration(days: 3)).toIso8601String(),
        ),
      ];
      final groups = NotificationGrouping.groupByDate(items);
      expect(groups.length, 2);
      expect(groups.first.group, NotificationTimeGroup.today);
    });
  });

  group('NotificationDeepLink', () {
    test('routes service request', () {
      final route = NotificationDeepLink.resolve(
        metadata: {'serviceRequestId': 'sr-1'},
        type: 'REQUEST_UPDATE',
      );
      expect(route, '/inbox/request/sr-1');
    });

    test('routes animal target', () {
      final route = NotificationDeepLink.resolve(
        metadata: {'target': 'animal', 'animalId': 'a-1'},
      );
      expect(route, '/animals/a-1');
    });

    test('falls back to inbox', () {
      expect(NotificationDeepLink.resolve(metadata: {}), '/inbox');
    });
  });
}
