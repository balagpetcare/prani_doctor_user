import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/presentation/home_providers.dart';
import 'vaccine_providers.dart';

abstract final class VaccineNavigation {
  VaccineNavigation._();

  static void afterSave(WidgetRef ref, {String? recordId}) {
    _invalidateAll(ref);
    if (recordId != null) ref.invalidate(vaccineRecordProvider(recordId));
  }

  static void afterDelete(WidgetRef ref) => _invalidateAll(ref);

  static void _invalidateAll(WidgetRef ref) {
    ref.invalidate(vaccineProvider);
    ref.invalidate(vaccineHistoryProvider);
    ref.invalidate(vaccineReminderProvider);
    ref.invalidate(vaccineSummaryProvider);
    ref.invalidate(vaccineCalendarProvider);
    ref.invalidate(dashboardProvider);
    ref.invalidate(dashboardMetricsProvider);
  }
}
