import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/presentation/home_providers.dart';
import 'feed_providers.dart';

abstract final class FeedNavigation {
  FeedNavigation._();

  static Future<void> refreshList(WidgetRef ref) async {
    await ref.read(feedListProvider.notifier).refresh();
  }

  static Future<void> refreshDetail(WidgetRef ref, String recordId) async {
    ref.invalidate(feedRecordProvider(recordId));
    await ref.read(feedRecordProvider(recordId).future);
  }

  static void afterSave(WidgetRef ref, {String? recordId}) {
    ref.invalidate(feedListProvider);
    ref.invalidate(feedCostSummaryProvider);
    ref.invalidate(feedCostProvider);
    ref.invalidate(feedAnalyticsProvider);
    ref.invalidate(dashboardProvider);
    ref.invalidate(dashboardMetricsProvider);
    if (recordId != null) {
      ref.invalidate(feedRecordProvider(recordId));
    }
  }

  static void afterDelete(WidgetRef ref) {
    ref.invalidate(feedListProvider);
    ref.invalidate(feedCostSummaryProvider);
    ref.invalidate(feedCostProvider);
    ref.invalidate(feedAnalyticsProvider);
    ref.invalidate(dashboardProvider);
    ref.invalidate(dashboardMetricsProvider);
  }
}
