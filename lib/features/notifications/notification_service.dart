import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firebase/firebase_bootstrap.dart';
import 'local_notification_service.dart';

typedef NotificationTapHandler = void Function(Map<String, dynamic>? metadata);

enum NotificationPermissionState {
  granted,
  denied,
  permanentlyDenied,
  notDetermined,
}

class NotificationPermissionStatus {
  const NotificationPermissionStatus(this.state);

  final NotificationPermissionState state;

  bool get isGranted => state == NotificationPermissionState.granted;
  bool get isDenied => state == NotificationPermissionState.denied;
  bool get isPermanentlyDenied =>
      state == NotificationPermissionState.permanentlyDenied;
}

class NotificationService {
  NotificationService({
    FirebaseMessaging? messaging,
    LocalNotificationService? local,
  }) : _messagingOverride = messaging,
       _local = local ?? LocalNotificationService();

  final FirebaseMessaging? _messagingOverride;
  final LocalNotificationService _local;
  FirebaseMessaging? _messaging;
  bool _initialized = false;

  FirebaseMessaging? _messagingIfReady() {
    if (_messagingOverride != null) return _messagingOverride;
    if (!isFirebaseReady) return null;
    return _messaging ??= FirebaseMessaging.instance;
  }

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

    if (!enablePush || !isFirebaseReady) {
      if (kDebugMode && enablePush && !isFirebaseReady) {
        debugPrint('[Push] skipped — Firebase not initialized');
      }
      _initialized = true;
      return;
    }

    final messaging = _messagingIfReady();
    if (messaging == null) {
      if (kDebugMode) {
        debugPrint('[Push] skipped — FirebaseMessaging unavailable');
      }
      _initialized = true;
      return;
    }

    try {
      await requestPermission();

      FirebaseMessaging.onMessage.listen(_showRemoteMessage);

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        onTap?.call(_metadataFromMessage(message));
      });

      messaging.onTokenRefresh.listen((token) {
        onTokenRefresh?.call(token);
      });

      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        onTap?.call(_metadataFromMessage(initial));
      }
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('[Push] skipped — ${e.code}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService push init skipped: $e');
      }
    }

    _initialized = true;
  }

  Future<NotificationPermissionStatus> getPermissionStatus() async {
    final messaging = _messagingIfReady();
    if (messaging == null) {
      return const NotificationPermissionStatus(
        NotificationPermissionState.notDetermined,
      );
    }
    try {
      final settings = await messaging.getNotificationSettings();
      return NotificationPermissionStatus(
        _mapAuthorization(settings.authorizationStatus),
      );
    } catch (e) {
      debugPrint('FCM getNotificationSettings failed: $e');
      return const NotificationPermissionStatus(
        NotificationPermissionState.notDetermined,
      );
    }
  }

  Future<NotificationPermissionStatus> requestPermission() async {
    final messaging = _messagingIfReady();
    if (messaging == null) {
      return const NotificationPermissionStatus(
        NotificationPermissionState.denied,
      );
    }
    try {
      final settings = await messaging.requestPermission();
      return NotificationPermissionStatus(
        _mapAuthorization(settings.authorizationStatus),
      );
    } catch (e) {
      debugPrint('FCM requestPermission failed: $e');
      return const NotificationPermissionStatus(
        NotificationPermissionState.denied,
      );
    }
  }

  NotificationPermissionState _mapAuthorization(AuthorizationStatus status) {
    return switch (status) {
      AuthorizationStatus.authorized ||
      AuthorizationStatus.provisional => NotificationPermissionState.granted,
      AuthorizationStatus.denied => NotificationPermissionState.denied,
      AuthorizationStatus.notDetermined =>
        NotificationPermissionState.notDetermined,
    };
  }

  Future<String?> getToken() async {
    final messaging = _messagingIfReady();
    if (messaging == null) return null;
    try {
      return await messaging.getToken();
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('[Push] skipped — ${e.code}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM getToken failed: $e');
      }
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
