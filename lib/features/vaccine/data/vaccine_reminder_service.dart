import '../../notifications/local_notification_service.dart';
import 'vaccine_dto.dart';

class VaccineReminderService {
  VaccineReminderService(this._local);

  final LocalNotificationService _local;

  Future<void> scheduleFallbackNotifications(
    VaccineRemindersData reminders, {
    required String overdueTitle,
    required String dueTitle,
    required String upcomingBody,
  }) async {
    for (final record in reminders.overdue) {
      await _local.show(
        id: _notificationId(record.id, suffix: 1),
        title: overdueTitle,
        body: '${record.vaccineName} · ${record.targetLabel}',
        payload: record.id,
      );
    }

    for (final record in reminders.upcoming.where((r) => r.status == VaccineStatus.due)) {
      await _local.show(
        id: _notificationId(record.id, suffix: 2),
        title: dueTitle,
        body: upcomingBody.replaceAll('{name}', record.vaccineName).replaceAll('{animal}', record.targetLabel),
        payload: record.id,
      );
    }

    final next = reminders.nextDue;
    if (next != null && next.status != VaccineStatus.completed && next.status != VaccineStatus.overdue) {
      await _local.show(
        id: _notificationId(next.id, suffix: 3),
        title: dueTitle,
        body: upcomingBody.replaceAll('{name}', next.vaccineName).replaceAll('{animal}', next.targetLabel),
        payload: next.id,
      );
    }
  }

  int _notificationId(String recordId, {required int suffix}) {
    return recordId.hashCode ^ suffix;
  }
}
