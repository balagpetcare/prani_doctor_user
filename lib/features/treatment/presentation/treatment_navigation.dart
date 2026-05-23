import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/presentation/home_providers.dart';
import 'treatment_providers.dart';

abstract final class TreatmentNavigation {
  TreatmentNavigation._();

  static void afterSave(WidgetRef ref, {String? recordId}) {
    _invalidateAll(ref);
    if (recordId != null) ref.invalidate(treatmentRecordProvider(recordId));
  }

  static void afterDelete(WidgetRef ref) => _invalidateAll(ref);

  static void _invalidateAll(WidgetRef ref) {
    ref.invalidate(treatmentProvider);
    ref.invalidate(treatmentSummaryProvider);
    ref.invalidate(treatmentTimelineProvider);
    ref.invalidate(treatmentMedicinePlanProvider);
    ref.invalidate(treatmentFollowUpProvider);
    ref.invalidate(dashboardProvider);
    ref.invalidate(dashboardMetricsProvider);
  }
}
