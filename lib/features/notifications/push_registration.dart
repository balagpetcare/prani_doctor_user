import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session/session_controller.dart';
import 'data/notification_repository.dart';
import 'notification_analytics.dart';
import 'notification_service.dart';

const _appVersion = '1.0.0';

String currentDevicePlatform() {
  if (kIsWeb) return 'web';
  if (Platform.isIOS) return 'ios';
  return 'android';
}

class PushRegistrationService {
  PushRegistrationService(this._ref);

  final Ref _ref;

  Future<String?> fetchPushToken() {
    return _ref.read(notificationServiceProvider).getToken();
  }

  Future<void> register({String? pushToken}) async {
    if (!_ref.read(sessionControllerProvider).isAuthenticated) return;

    final token = pushToken ?? await fetchPushToken();
    final deviceKey = await _ref.read(sessionControllerProvider.notifier).deviceKey();

    await _ref.read(deviceRepositoryProvider).registerDevice(
          deviceKey: deviceKey,
          platform: currentDevicePlatform(),
          pushToken: token,
          appVersion: _appVersion,
        );
    NotificationAnalytics.pushTokenRegistered();
  }
}

final pushRegistrationProvider = Provider<PushRegistrationService>((ref) {
  return PushRegistrationService(ref);
});
