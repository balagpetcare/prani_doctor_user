import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_env.dart';
import '../../core/firebase/firebase_bootstrap.dart';
import '../../core/session/session_auth.dart';
import '../../core/session/session_controller.dart';
import 'data/notification_repository.dart';
import 'notification_analytics.dart';
import 'notification_service.dart';

const _appVersion = '1.0.0';
const _pushTokenTimeout = Duration(seconds: 4);

String currentDevicePlatform() {
  if (kIsWeb) return 'web';
  if (Platform.isIOS) return 'ios';
  return 'android';
}

class PushRegistrationService {
  PushRegistrationService(this._ref);

  final Ref _ref;

  /// Optional FCM token for auth/device registration — never blocks login.
  Future<String?> fetchPushToken() async {
    if (!AppEnv.fromEnvironment().enablePush) {
      _logSkipped('push disabled in build config');
      return null;
    }
    if (!isFirebaseReady) {
      _logSkipped('Firebase not initialized');
      _logAuthContinue();
      return null;
    }

    try {
      final token = await _ref
          .read(notificationServiceProvider)
          .getToken()
          .timeout(
            _pushTokenTimeout,
            onTimeout: () {
              _logSkipped('getToken timeout');
              return null;
            },
          );
      if (token == null || token.isEmpty) {
        _logSkipped('no FCM token');
        _logAuthContinue();
      }
      return token;
    } on FirebaseException catch (e) {
      _logSkipped(e.code);
      _logAuthContinue();
      return null;
    } catch (e) {
      _logSkipped(e.toString());
      _logAuthContinue();
      return null;
    }
  }

  Future<void> register({String? pushToken}) async {
    if (!SessionAuth.canCallProtectedApis(
      _ref.read(sessionControllerProvider),
    )) {
      return;
    }

    final token = pushToken ?? await fetchPushToken();
    final deviceKey = await _ref
        .read(sessionControllerProvider.notifier)
        .deviceKey();

    await _ref
        .read(deviceRepositoryProvider)
        .registerDevice(
          deviceKey: deviceKey,
          platform: currentDevicePlatform(),
          pushToken: token,
          appVersion: _appVersion,
        );
    NotificationAnalytics.pushTokenRegistered();
  }

  void _logSkipped(String reason) {
    if (kDebugMode) {
      debugPrint('[Push] skipped — $reason');
    }
  }

  void _logAuthContinue() {
    if (kDebugMode) {
      debugPrint('[Auth] continue without push');
    }
  }
}

final pushRegistrationProvider = Provider<PushRegistrationService>((ref) {
  return PushRegistrationService(ref);
});
