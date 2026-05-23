import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/auto_refresh_guard.dart';
import '../../animals/presentation/animal_providers.dart';
import '../../notifications/presentation/notification_providers.dart';
import '../../offline/data/sync_coordinator.dart';
import '../../profile/presentation/profile_providers.dart';
import 'home_analytics.dart';
import 'home_providers.dart';

/// Dashboard refresh + section invalidation helpers.
abstract final class HomeNavigation {
  HomeNavigation._();

  static Future<void> refreshDashboard(WidgetRef ref) {
    return ref.runWithManualRefresh(() async {
      HomeAnalytics.pullToRefresh();
      unawaited(
        ref.read(syncCoordinatorProvider).syncNow(background: true).then((_) {
          HomeAnalytics.backgroundSyncTriggered();
        }),
      );

      await ref
          .read(dashboardProvider.notifier)
          .refresh(invalidateSections: true);

      ref.invalidate(mobileMeProvider);

      await Future.wait([
        ref
            .read(mobileMeProvider.notifier)
            .reload(forceRefresh: true)
            .catchError((_) {}),
        ref
            .read(animalListProvider.notifier)
            .refresh(silent: true)
            .catchError((_) {}),
        ref
            .read(notificationListProvider.notifier)
            .refresh(silent: true)
            .catchError((_) {}),
      ]);
    });
  }

  static void handleDeepLinkEntry(WidgetRef ref, {bool refresh = false}) {
    if (refresh) {
      ref
          .read(dashboardProvider.notifier)
          .refresh(silent: true, invalidateSections: true);
    }
  }
}
