import 'package:flutter/foundation.dart';

/// Lightweight analytics hooks for notification flows (debug-first; wire to telemetry later).
abstract final class NotificationAnalytics {
  NotificationAnalytics._();

  static void listOpened() => _log('notification_list_opened');
  static void listRefreshed() => _log('notification_list_refreshed');
  static void markRead(String id) => _log('notification_mark_read', {'id': id});
  static void markAllRead() => _log('notification_mark_all_read');
  static void deleted(String id) => _log('notification_deleted', {'id': id});
  static void settingsOpened() => _log('notification_settings_opened');
  static void settingsSaved() => _log('notification_settings_saved');
  static void pushTap({String? route}) => _log('notification_push_tap', {'route': route});
  static void pushTokenRegistered() => _log('notification_push_token_registered');

  static void _log(String event, [Map<String, Object?> params = const {}]) {
    if (kDebugMode) {
      debugPrint('[analytics] $event ${params.isEmpty ? '' : params}');
    }
  }
}
