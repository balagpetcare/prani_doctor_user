import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Configure after `DefaultFirebaseOptions` / `google-services.json` exist.
class NotificationService {
  NotificationService({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  Future<void> initialize({required bool enablePush}) async {
    if (!enablePush) return;
    try {
      await _messaging.requestPermission();
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM foreground: ${message.messageId}');
      });
      final token = await _messaging.getToken();
      debugPrint('FCM token: $token');
    } catch (e) {
      debugPrint('NotificationService init skipped: $e');
    }
  }
}
