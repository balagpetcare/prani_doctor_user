import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_status_chip.dart';
import '../data/service_request_dto.dart';

class ServiceRequestStatusChip extends StatelessWidget {
  const ServiceRequestStatusChip({super.key, required this.status});

  final ServiceRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppStatusChip(label: _label(l10n), tone: _tone);
  }

  String _label(AppLocalizations l10n) => switch (status) {
    ServiceRequestStatus.pending => l10n.statusPending,
    ServiceRequestStatus.assigned => l10n.statusAssigned,
    ServiceRequestStatus.accepted => l10n.statusAccepted,
    ServiceRequestStatus.inProgress => l10n.statusInProgress,
    ServiceRequestStatus.completed => l10n.statusCompleted,
    ServiceRequestStatus.cancelled => l10n.statusCancelled,
    ServiceRequestStatus.rejected => l10n.statusRejected,
  };

  StatusTone get _tone => switch (status) {
    ServiceRequestStatus.pending => StatusTone.warning,
    ServiceRequestStatus.assigned => StatusTone.info,
    ServiceRequestStatus.accepted => StatusTone.info,
    ServiceRequestStatus.inProgress => StatusTone.neutral,
    ServiceRequestStatus.completed => StatusTone.positive,
    ServiceRequestStatus.cancelled => StatusTone.muted,
    ServiceRequestStatus.rejected => StatusTone.danger,
  };
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
