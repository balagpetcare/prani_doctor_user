import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/presentation/home_providers.dart';
import 'batch_providers.dart';

abstract final class BatchNavigation {
  BatchNavigation._();

  static Future<void> refreshList(WidgetRef ref) async {
    await ref.read(batchListProvider.notifier).refresh();
  }

  static Future<void> refreshDetail(WidgetRef ref, String batchId) async {
    ref.invalidate(batchDetailProvider(batchId));
    await ref.read(batchDetailProvider(batchId).future);
  }

  static void afterSave(WidgetRef ref, String batchId) {
    ref.invalidate(batchListProvider);
    ref.invalidate(batchDetailProvider(batchId));
    ref.invalidate(batchOptionsProvider);
    ref.invalidate(dashboardProvider);
    ref.invalidate(dashboardMetricsProvider);
  }

  static void afterDelete(WidgetRef ref) {
    ref.invalidate(batchListProvider);
    ref.invalidate(batchOptionsProvider);
    ref.invalidate(dashboardProvider);
    ref.invalidate(dashboardMetricsProvider);
  }
}
