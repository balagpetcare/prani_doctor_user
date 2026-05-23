import '../../notifications/local_notification_service.dart';
import 'treatment_dto.dart';

class TreatmentFollowUpService {
  TreatmentFollowUpService(this._local);

  final LocalNotificationService _local;

  Future<void> scheduleFollowUpReminders(
    List<FarmTreatment> treatments, {
    required String title,
    required String Function(FarmTreatment treatment) bodyFor,
  }) async {
    final now = DateTime.now();
    for (final treatment in treatments) {
      if (treatment.status != TreatmentStatus.active ||
          treatment.endDate == null) {
        continue;
      }
      final end = treatment.endDate!;
      if (end.isBefore(now) || end.difference(now).inDays <= 7) {
        await _local.show(
          id: treatment.id.hashCode,
          title: title,
          body: bodyFor(treatment),
          payload: treatment.id,
        );
      }
    }
  }
}
