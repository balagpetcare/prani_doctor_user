import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/presentation/home_providers.dart';
import 'milk_providers.dart';

abstract final class MilkNavigation {
  MilkNavigation._();

  static Future<void> refreshList(WidgetRef ref) async {
    await ref.read(milkListProvider.notifier).refresh();
  }

  static Future<void> refreshDetail(WidgetRef ref, String recordId) async {
    ref.invalidate(milkRecordProvider(recordId));
    await ref.read(milkRecordProvider(recordId).future);
  }

  static Future<void> afterSave(WidgetRef ref, {String? recordId}) async {
    await _invalidateAnalytics(ref);
    if (recordId != null) {
      ref.invalidate(milkRecordProvider(recordId));
    }
  }

  static Future<void> afterDelete(WidgetRef ref) async {
    await _invalidateAnalytics(ref);
  }

  static Future<void> _invalidateAnalytics(WidgetRef ref) async {
    ref.invalidate(milkListProvider);
    ref.invalidate(milkTodaySummaryProvider);
    ref.invalidate(milkSummaryProvider);
    ref.invalidate(milkChartsProvider);
    ref.invalidate(dashboardProvider);
    ref.invalidate(dashboardMetricsProvider);
  }
}
