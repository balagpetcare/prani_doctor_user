import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

typedef LocalNotificationTapHandler = void Function(String? payload);

class LocalNotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  static const _channelId = 'pranidoctor_updates';
  static const _channelName = 'PraniDoctor updates';

  Future<void> initialize({LocalNotificationTapHandler? onTap}) async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        onTap?.call(response.payload);
      },
    );

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              importance: Importance.high,
            ),
          );
    }
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }
}
