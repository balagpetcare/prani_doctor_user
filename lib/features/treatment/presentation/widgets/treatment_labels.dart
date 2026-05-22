import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../data/treatment_dto.dart';

String treatmentStatusLabel(AppLocalizations l10n, TreatmentStatus status) {
  return switch (status) {
    TreatmentStatus.active => l10n.treatmentStatusActive,
    TreatmentStatus.completed => l10n.treatmentStatusCompleted,
    TreatmentStatus.cancelled => l10n.treatmentStatusCancelled,
  };
}
