import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../data/vaccine_dto.dart';

String vaccineStatusLabel(AppLocalizations l10n, VaccineStatus status) {
  return switch (status) {
    VaccineStatus.scheduled => l10n.vaccineStatusScheduled,
    VaccineStatus.due => l10n.vaccineStatusDue,
    VaccineStatus.overdue => l10n.vaccineStatusOverdue,
    VaccineStatus.completed => l10n.vaccineStatusCompleted,
  };
}
