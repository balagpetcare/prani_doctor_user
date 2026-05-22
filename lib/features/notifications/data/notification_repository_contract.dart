import '../../../core/error/api_result.dart';
import 'notification_dto.dart';

abstract class NotificationRepositoryContract {
  Future<NotificationListResultDto?> readCachedList();

  Future<int?> readCachedUnreadCount();

  Future<NotificationSettingsDto?> readCachedSettings();

  Future<ApiResult<NotificationListResultDto>> listNotifications({
    int limit,
    int offset,
    bool unreadOnly,
    bool forceRefresh,
  });

  Future<ApiResult<int>> getUnreadCount({bool forceRefresh});

  Future<ApiResult<MobileNotificationDto>> markRead(String id);

  Future<ApiResult<int>> markAllRead();

  Future<ApiResult<void>> deleteNotification(String id);

  Future<ApiResult<NotificationSettingsDto>> getSettings({bool forceRefresh});

  Future<ApiResult<NotificationSettingsDto>> saveSettings(NotificationSettingsDto settings);
}
