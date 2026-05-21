import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../data/service_request_dto.dart';

class ServiceRequestStatusChip extends StatelessWidget {
  const ServiceRequestStatusChip({super.key, required this.status});

  final ServiceRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, color) = _labelAndColor(l10n);
    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
    );
  }

  (String, Color) _labelAndColor(AppLocalizations l10n) {
    switch (status) {
      case ServiceRequestStatus.pending:
        return (l10n.statusPending, Colors.orange);
      case ServiceRequestStatus.assigned:
        return (l10n.statusAssigned, Colors.blue);
      case ServiceRequestStatus.accepted:
        return (l10n.statusAccepted, Colors.indigo);
      case ServiceRequestStatus.inProgress:
        return (l10n.statusInProgress, Colors.deepPurple);
      case ServiceRequestStatus.completed:
        return (l10n.statusCompleted, Colors.green);
      case ServiceRequestStatus.cancelled:
        return (l10n.statusCancelled, Colors.grey);
      case ServiceRequestStatus.rejected:
        return (l10n.statusRejected, Colors.red);
    }
  }
}

String serviceTypeLabel(AppLocalizations l10n, String serviceType) {
  switch (serviceType) {
    case 'DOCTOR_HOME_VISIT':
      return l10n.homeVisit;
    case 'EMERGENCY_DOCTOR':
      return l10n.filterEmergency;
    case 'ONLINE_CONSULTATION_LATER':
      return l10n.onlineConsultation;
    case 'AI_SERVICE':
      return l10n.aiService;
    default:
      return serviceType;
  }
}

String timelineEventLabel(AppLocalizations l10n, String eventType) {
  switch (eventType) {
    case 'CREATED':
      return l10n.eventCreated;
    case 'ASSIGNED':
      return l10n.eventAssigned;
    case 'REASSIGNED':
      return l10n.eventReassigned;
    case 'ACCEPTED':
      return l10n.eventAccepted;
    case 'REJECTED':
      return l10n.eventRejected;
    case 'STARTED':
      return l10n.eventStarted;
    case 'NOTE_ADDED':
      return l10n.eventNoteAdded;
    case 'CASE_OPENED':
      return l10n.eventCaseOpened;
    case 'CASE_UPDATED':
      return l10n.eventCaseUpdated;
    case 'COMPLETED':
      return l10n.eventCompleted;
    case 'CANCELLED':
      return l10n.eventCancelled;
    default:
      return eventType;
  }
}

String formatTimestamp(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return iso;
  return '${parsed.toLocal()}'.split('.').first;
}
