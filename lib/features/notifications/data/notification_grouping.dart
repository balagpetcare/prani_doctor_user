import 'notification_dto.dart';

abstract final class NotificationGrouping {
  NotificationGrouping._();

  static List<NotificationGroupedSection> groupByDate(
    List<MobileNotificationDto> items,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final buckets = <NotificationTimeGroup, List<MobileNotificationDto>>{
      NotificationTimeGroup.today: [],
      NotificationTimeGroup.yesterday: [],
      NotificationTimeGroup.earlier: [],
    };

    for (final item in items) {
      final created = DateTime.tryParse(item.createdAt)?.toLocal();
      if (created == null) {
        buckets[NotificationTimeGroup.earlier]!.add(item);
        continue;
      }
      final day = DateTime(created.year, created.month, created.day);
      if (day == today) {
        buckets[NotificationTimeGroup.today]!.add(item);
      } else if (day == yesterday) {
        buckets[NotificationTimeGroup.yesterday]!.add(item);
      } else {
        buckets[NotificationTimeGroup.earlier]!.add(item);
      }
    }

    return NotificationTimeGroup.values
        .where((g) => buckets[g]!.isNotEmpty)
        .map((g) => NotificationGroupedSection(group: g, items: buckets[g]!))
        .toList();
  }
}
