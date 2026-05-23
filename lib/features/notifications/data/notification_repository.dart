import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_result.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_helpers.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/offline/local_cache_contract.dart';
import '../../offline/data/local_cache_service.dart';
import '../../offline/offline_providers.dart';
import 'notification_api_paths.dart';
import 'notification_dto.dart';
import 'notification_repository_contract.dart';

class NotificationRepository implements NotificationRepositoryContract {
  NotificationRepository(this._dio, this._cache);

  final Dio _dio;
  final LocalCacheService _cache;

  Future<ApiResult<NotificationListResultDto>>? _listInFlight;

  NotificationListResultDto? _parseListCache(Map<String, dynamic>? cached) {
    if (cached == null) return null;
    final items = (cached['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((j) => MobileNotificationDto.fromJson(j, fromCache: true))
        .toList();
    return NotificationListResultDto(
      items: items,
      total: cached['total'] as int? ?? items.length,
      fromCache: true,
    );
  }

  Future<void> _writeListCache(NotificationListResultDto page) async {
    await _cache.write(LocalCacheContract.notificationsListKey, {
      'items': page.items.map((i) => i.toJson()).toList(),
      'total': page.total,
    }, LocalCacheContract.profileTtl);
  }

  @override
  Future<NotificationListResultDto?> readCachedList() async {
    return _parseListCache(
      await _cache.read(LocalCacheContract.notificationsListKey),
    );
  }

  @override
  Future<int?> readCachedUnreadCount() async {
    final cached = await _cache.read(
      LocalCacheContract.notificationsUnreadCountKey,
    );
    return cached?['count'] as int?;
  }

  @override
  Future<NotificationSettingsDto?> readCachedSettings() async {
    final cached = await _cache.read(
      LocalCacheContract.notificationSettingsKey,
    );
    if (cached == null) return null;
    return NotificationSettingsDto.fromJson(cached, fromCache: true);
  }

  @override
  Future<ApiResult<NotificationListResultDto>> listNotifications({
    int limit = 20,
    int offset = 0,
    bool unreadOnly = false,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && offset == 0 && _listInFlight != null) {
      return _listInFlight!;
    }
    final future = _loadList(
      limit: limit,
      offset: offset,
      unreadOnly: unreadOnly,
    );
    if (offset == 0) _listInFlight = future;
    try {
      return await future;
    } finally {
      if (offset == 0) _listInFlight = null;
    }
  }

  Future<ApiResult<NotificationListResultDto>> _loadList({
    required int limit,
    required int offset,
    required bool unreadOnly,
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
      final page = NotificationListResultDto(
        items: items,
        total: data['total'] as int? ?? items.length,
      );
      if (offset == 0 && !unreadOnly) await _writeListCache(page);
      return ApiResult.success(page);
    } on AppException catch (e) {
      if (offset == 0 && !unreadOnly) {
        final cached = await readCachedList();
        if (cached != null) return ApiResult.success(cached);
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<int>> getUnreadCount({bool forceRefresh = false}) async {
    try {
      final data = await getJson(_dio, NotificationApiPaths.unreadCount);
      final count = data['count'] as int? ?? 0;
      await _cache.write(
        LocalCacheContract.notificationsUnreadCountKey,
        {'count': count},
        LocalCacheContract.profileTtl,
      );
      return ApiResult.success(count);
    } on AppException catch (e) {
      final cached = await readCachedUnreadCount();
      if (cached != null) return ApiResult.success(cached);
      return ApiResult.failure(e);
    }
  }

  Future<void> _optimisticMarkRead(String id) async {
    final cached = await readCachedList();
    if (cached == null) return;
    final updated = cached.items
        .map(
          (n) => n.id == id
              ? n.copyWith(readAt: DateTime.now().toIso8601String())
              : n,
        )
        .toList();
    await _writeListCache(
      NotificationListResultDto(items: updated, total: cached.total),
    );
  }

  Future<void> _optimisticRemove(String id) async {
    final cached = await readCachedList();
    if (cached == null) return;
    final updated = cached.items.where((n) => n.id != id).toList();
    await _writeListCache(
      NotificationListResultDto(items: updated, total: updated.length),
    );
  }

  @override
  Future<ApiResult<MobileNotificationDto>> markRead(String id) async {
    await _optimisticMarkRead(id);
    try {
      final data = await patchJson(_dio, NotificationApiPaths.markRead(id), {});
      final notification = data['notification'];
      if (notification is! Map<String, dynamic>) {
        return const ApiResult.failure(
          AppException(message: 'Invalid response'),
        );
      }
      return ApiResult.success(MobileNotificationDto.fromJson(notification));
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<int>> markAllRead() async {
    try {
      final data = await patchJson(_dio, NotificationApiPaths.readAll, {});
      final cached = await readCachedList();
      if (cached != null) {
        final updated = cached.items
            .map(
              (n) => n.copyWith(
                readAt: n.readAt ?? DateTime.now().toIso8601String(),
              ),
            )
            .toList();
        await _writeListCache(
          NotificationListResultDto(items: updated, total: cached.total),
        );
      }
      await _cache.write(
        LocalCacheContract.notificationsUnreadCountKey,
        {'count': 0},
        LocalCacheContract.profileTtl,
      );
      return ApiResult.success(data['updatedCount'] as int? ?? 0);
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<void>> deleteNotification(String id) async {
    await _optimisticRemove(id);
    try {
      await deleteJson(_dio, NotificationApiPaths.notification(id));
      return const ApiResult.success(null);
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<NotificationSettingsDto>> getSettings({
    bool forceRefresh = false,
  }) async {
    try {
      final data = await getJson(_dio, NotificationApiPaths.settings);
      final raw = data['settings'];
      if (raw is! Map<String, dynamic>) {
        return const ApiResult.failure(
          AppException(message: 'Invalid settings response'),
        );
      }
      final settings = NotificationSettingsDto.fromJson(raw);
      await _cache.write(
        LocalCacheContract.notificationSettingsKey,
        settings.toJson(),
        LocalCacheContract.profileTtl,
      );
      return ApiResult.success(settings);
    } on AppException catch (e) {
      final cached = await readCachedSettings();
      if (cached != null) return ApiResult.success(cached);
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<NotificationSettingsDto>> saveSettings(
    NotificationSettingsDto settings,
  ) async {
    await _cache.write(
      LocalCacheContract.notificationSettingsKey,
      settings.toJson(),
      LocalCacheContract.profileTtl,
    );
    try {
      final data = await putJson(
        _dio,
        NotificationApiPaths.settings,
        settings.toJson(),
      );
      final raw = data['settings'];
      if (raw is! Map<String, dynamic>) {
        return const ApiResult.failure(
          AppException(message: 'Invalid settings response'),
        );
      }
      final saved = NotificationSettingsDto.fromJson(raw);
      await _cache.write(
        LocalCacheContract.notificationSettingsKey,
        saved.toJson(),
        LocalCacheContract.profileTtl,
      );
      return ApiResult.success(saved);
    } on AppException catch (e) {
      return ApiResult.failure(e);
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
        if (appVersion != null && appVersion.isNotEmpty)
          'appVersion': appVersion,
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

final notificationRepositoryProvider = Provider<NotificationRepositoryContract>(
  (ref) {
    return NotificationRepository(
      ref.watch(dioProvider),
      ref.watch(localCacheServiceProvider),
    );
  },
);

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepository(ref.watch(dioProvider));
});
