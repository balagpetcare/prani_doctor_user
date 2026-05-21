abstract final class NotificationApiPaths {
  NotificationApiPaths._();

  static const notifications = '/api/mobile/notifications';
  static String markRead(String id) => '/api/mobile/notifications/$id/read';
  static const readAll = '/api/mobile/notifications/read-all';
  static const registerDevice = '/api/mobile/devices/register';
}
