abstract final class NotificationApiPaths {
  NotificationApiPaths._();

  static const notifications = '/api/mobile/notifications';
  static const unreadCount = '/api/mobile/notifications/unread-count';
  static const settings = '/api/mobile/notifications/settings';
  static String markRead(String id) => '/api/mobile/notifications/$id/read';
  static String notification(String id) => '/api/mobile/notifications/$id';
  static const readAll = '/api/mobile/notifications/read-all';
  static const registerDevice = '/api/mobile/devices/register';
}
