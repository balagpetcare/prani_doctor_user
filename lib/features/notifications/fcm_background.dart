import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/logging/crash_reporting_context.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await _handleBackgroundMessage(message);
  } catch (error, stack) {
    await _reportBackgroundFailure(error, stack);
  }
}

Future<void> _handleBackgroundMessage(RemoteMessage message) async {
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

Future<void> _reportBackgroundFailure(Object error, StackTrace stack) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    await FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      fatal: false,
      reason: 'FCM background handler',
      information: [
        'category=${CrashErrorCategory.backgroundIsolate}',
        'app_env=${CrashReportingContext.appEnvironment.name}',
        if (CrashReportingContext.releaseName != null)
          'release=${CrashReportingContext.releaseName}',
      ],
    );
  } catch (_) {
    // Cannot report from background isolate — swallow to avoid crash loop.
  }
}
