import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final notification = message.notification;
  if (notification == null) return;

  const channel = AndroidNotificationChannel(
    'pranidoctor_updates',
    'PraniDoctor updates',
    importance: Importance.high,
  );

  final plugin = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await plugin.initialize(
    settings: const InitializationSettings(android: androidInit),
  );

  await plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  final payload = message.data.isEmpty ? null : jsonEncode(message.data);

  await plugin.show(
    id: notification.title.hashCode,
    title: notification.title ?? 'PraniDoctor',
    body: notification.body ?? '',
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'pranidoctor_updates',
        'PraniDoctor updates',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
    payload: payload,
  );
}
