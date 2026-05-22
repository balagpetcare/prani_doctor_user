import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../data/health_dto.dart';

String healthEventTypeLabel(AppLocalizations l10n, HealthEventType type) {
  return switch (type) {
    HealthEventType.symptom => l10n.healthTypeSymptom,
    HealthEventType.diagnosis => l10n.healthTypeDiagnosis,
    HealthEventType.disease => l10n.healthTypeDisease,
    HealthEventType.checkup => l10n.healthTypeCheckup,
    HealthEventType.treatmentRef => l10n.healthTypeTreatmentRef,
  };
}
