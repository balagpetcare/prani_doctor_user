import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_notification_service.dart';

typedef NotificationTapHandler = void Function(Map<String, dynamic>? metadata);

class NotificationService {
  NotificationService({
    FirebaseMessaging? messaging,
    LocalNotificationService? local,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _local = local ?? LocalNotificationService();

  final FirebaseMessaging _messaging;
  final LocalNotificationService _local;
  bool _initialized = false;

  Future<void> initialize({
    required bool enablePush,
    required bool enableLocal,
    NotificationTapHandler? onTap,
    void Function(String token)? onTokenRefresh,
  }) async {
    if (_initialized) return;

    if (enableLocal) {
      await _local.initialize(
        onTap: (payload) {
          if (payload == null || payload.isEmpty) {
            onTap?.call(null);
            return;
          }
          try {
            final decoded = jsonDecode(payload);
            if (decoded is Map<String, dynamic>) {
              onTap?.call(decoded);
            } else {
              onTap?.call(null);
            }
          } catch (_) {
            onTap?.call(null);
          }
        },
      );
    }

    if (!enablePush) {
      _initialized = true;
      return;
    }

    try {
      await _messaging.requestPermission();

      FirebaseMessaging.onMessage.listen((message) {
        _showRemoteMessage(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        onTap?.call(_metadataFromMessage(message));
      });

      _messaging.onTokenRefresh.listen((token) {
        onTokenRefresh?.call(token);
      });

      final initial = await _messaging.getInitialMessage();
      if (initial != null) {
        onTap?.call(_metadataFromMessage(initial));
      }
    } catch (e) {
      debugPrint('NotificationService push init skipped: $e');
    }

    _initialized = true;
  }

  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('FCM getToken failed: $e');
      return null;
    }
  }

  Future<void> showLocal({
    required String title,
    required String body,
    Map<String, dynamic>? metadata,
  }) async {
    final payload = metadata == null ? null : jsonEncode(metadata);
    await _local.show(
      id: title.hashCode ^ body.hashCode,
      title: title,
      body: body,
      payload: payload,
    );
  }

  void _showRemoteMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    showLocal(
      title: notification.title ?? 'PraniDoctor',
      body: notification.body ?? '',
      metadata: _metadataFromMessage(message),
    );
  }

  Map<String, dynamic>? _metadataFromMessage(RemoteMessage message) {
    final data = message.data;
    if (data.isEmpty) return null;
    return Map<String, dynamic>.from(data);
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
