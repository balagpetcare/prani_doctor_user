import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/presentation/home_providers.dart';
import 'health_providers.dart';

abstract final class HealthNavigation {
  HealthNavigation._();

  static void afterSave(WidgetRef ref, {String? recordId}) {
    _invalidateAll(ref);
    if (recordId != null) ref.invalidate(healthRecordProvider(recordId));
  }

  static void afterDelete(WidgetRef ref) => _invalidateAll(ref);

  static void _invalidateAll(WidgetRef ref) {
    ref.invalidate(healthProvider);
    ref.invalidate(healthTimelineProvider);
    ref.invalidate(healthSummaryProvider);
    ref.invalidate(healthAnalyticsProvider);
    ref.invalidate(healthRecentEventsProvider);
    ref.invalidate(dashboardProvider);
    ref.invalidate(dashboardMetricsProvider);
  }
}
