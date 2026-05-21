import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_result.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_helpers.dart';
import '../../../core/network/dio_provider.dart';
import 'notification_api_paths.dart';
import 'notification_dto.dart';

class NotificationRepository {
  NotificationRepository(this._dio);

  final Dio _dio;

  Future<ApiResult<NotificationListResultDto>> listNotifications({
    int limit = 20,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    try {
      final data = await getJson(
        _dio,
        NotificationApiPaths.notifications,
        queryParameters: {
          'limit': limit,
          'offset': offset,
          if (unreadOnly) 'unreadOnly': 'true',
        },
      );
      final items = (data['items'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(MobileNotificationDto.fromJson)
          .toList();
      return ApiResult.success(
        NotificationListResultDto(
          items: items,
          total: data['total'] as int? ?? items.length,
        ),
      );
    } on AppException catch (e) {
      return ApiResult.failure(e);
    } catch (e) {
      return ApiResult.failure(
        AppException(message: 'Could not load notifications', cause: e),
      );
    }
  }

  Future<ApiResult<int>> getUnreadCount() async {
    final result = await listNotifications(unreadOnly: true, limit: 1, offset: 0);
    return result.when(
      success: (data) => ApiResult.success(data.total),
      failure: (e) => ApiResult.failure(e),
    );
  }

  Future<ApiResult<MobileNotificationDto>> markRead(String id) async {
    try {
      final data = await patchJson(_dio, NotificationApiPaths.markRead(id), {});
      final notification = data['notification'];
      if (notification is! Map<String, dynamic>) {
        return ApiResult.failure(const AppException(message: 'Invalid response'));
      }
      return ApiResult.success(MobileNotificationDto.fromJson(notification));
    } on AppException catch (e) {
      return ApiResult.failure(e);
    } catch (e) {
      return ApiResult.failure(
        AppException(message: 'Could not mark notification read', cause: e),
      );
    }
  }

  Future<ApiResult<int>> markAllRead() async {
    try {
      final data = await patchJson(_dio, NotificationApiPaths.readAll, {});
      return ApiResult.success(data['updatedCount'] as int? ?? 0);
    } on AppException catch (e) {
      return ApiResult.failure(e);
    } catch (e) {
      return ApiResult.failure(
        AppException(message: 'Could not mark all read', cause: e),
      );
    }
  }
}

class DeviceRepository {
  DeviceRepository(this._dio);

  final Dio _dio;

  Future<ApiResult<DeviceRegistrationResultDto>> registerDevice({
    required String deviceKey,
    required String platform,
    String? pushToken,
    String? appVersion,
  }) async {
    try {
      final data = await postJson(_dio, NotificationApiPaths.registerDevice, {
        'deviceKey': deviceKey,
        'platform': platform,
        if (pushToken != null && pushToken.isNotEmpty) 'pushToken': pushToken,
        if (appVersion != null && appVersion.isNotEmpty) 'appVersion': appVersion,
      });
      return ApiResult.success(DeviceRegistrationResultDto.fromJson(data));
    } on AppException catch (e) {
      return ApiResult.failure(e);
    } catch (e) {
      return ApiResult.failure(
        AppException(message: 'Could not register device', cause: e),
      );
    }
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(dioProvider));
});

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepository(ref.watch(dioProvider));
});

final notificationListProvider = FutureProvider<List<MobileNotificationDto>>((ref) async {
  final result = await ref.read(notificationRepositoryProvider).listNotifications(limit: 50);
  return result.when(
    success: (data) => data.items,
    failure: (e) => throw e,
  );
});

final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final result = await ref.read(notificationRepositoryProvider).getUnreadCount();
  return result.when(
    success: (count) => count,
    failure: (e) => throw e,
  );
});
