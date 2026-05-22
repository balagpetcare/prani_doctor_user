import '../../../routing/app_routes.dart';

/// Resolves notification metadata to an in-app route with safe fallbacks.
abstract final class NotificationDeepLink {
  NotificationDeepLink._();

  static String resolve({
    Map<String, dynamic>? metadata,
    String? type,
  }) {
    final meta = metadata ?? const {};
    final target = _string(meta['target'])?.toLowerCase();
    final event = _string(meta['event'])?.toLowerCase();

    if (target == 'dashboard' || target == 'home') return AppRoutes.home;
    if (target == 'appointment' || target == 'order' || target == 'service') {
      final id = _string(meta['serviceRequestId']) ?? _string(meta['orderId']);
      if (id != null) return AppRoutes.serviceRequestDetail(id);
      return AppRoutes.inbox;
    }
    if (target == 'animal') {
      final id = _string(meta['animalId']);
      if (id != null) return AppRoutes.animalDetail(id);
      return AppRoutes.animals;
    }
    if (target == 'medicine' || target == 'treatment') {
      final id = _string(meta['treatmentId']);
      if (id != null) return AppRoutes.treatmentDetail(id);
      return AppRoutes.treatments;
    }
    if (target == 'support' || target == 'complaint') {
      final id = _string(meta['ticketId']) ?? _string(meta['supportTicketId']);
      if (id != null) return AppRoutes.supportTicketDetail(id);
      return AppRoutes.supportTickets;
    }

    final serviceRequestId = _string(meta['serviceRequestId']);
    if (serviceRequestId != null) return AppRoutes.serviceRequestDetail(serviceRequestId);

    final animalId = _string(meta['animalId']);
    if (animalId != null) return AppRoutes.animalDetail(animalId);

    final treatmentId = _string(meta['treatmentId']);
    if (treatmentId != null) return AppRoutes.treatmentDetail(treatmentId);

    if (type == 'PAYMENT' || event == 'payment') return AppRoutes.inbox;
    if (type == 'CHAT') return AppRoutes.inbox;

    return AppRoutes.inbox;
  }

  static String? _string(dynamic value) {
    if (value is String && value.isNotEmpty) return value;
    return null;
  }
}
