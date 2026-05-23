import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/presentation/home_providers.dart';
import 'notification_providers.dart';

abstract final class NotificationNavigation {
  NotificationNavigation._();

  static void afterRead(WidgetRef ref) {
    ref.invalidate(unreadNotificationCountProvider);
    ref.invalidate(dashboardProvider);
    ref.invalidate(dashboardMetricsProvider);
  }

  static void afterListMutation(WidgetRef ref) {
    ref.invalidate(unreadNotificationCountProvider);
    ref.invalidate(dashboardProvider);
    ref.invalidate(dashboardMetricsProvider);
  }

  static void afterSettingsSave(WidgetRef ref) {
    ref.invalidate(notificationSettingsProvider);
  }

  static void invalidateAll(WidgetRef ref) {
    ref.invalidate(notificationListProvider);
    ref.invalidate(unreadNotificationCountProvider);
    ref.invalidate(notificationSettingsProvider);
    ref.invalidate(dashboardProvider);
    ref.invalidate(dashboardMetricsProvider);
  }
}
