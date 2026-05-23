import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_env.dart';
import '../../core/firebase/firebase_bootstrap.dart';
import '../../core/session/session_auth.dart';
import '../../core/session/session_controller.dart';
import '../../core/session/session_state.dart';
import '../../routing/app_router.dart';
import 'notification_deeplink.dart';
import 'notification_analytics.dart';
import 'notification_realtime.dart';
import 'notification_service.dart';
import 'push_registration.dart';

class NotificationCoordinator extends ConsumerStatefulWidget {
  const NotificationCoordinator({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationCoordinator> createState() =>
      _NotificationCoordinatorState();
}

class _NotificationCoordinatorState
    extends ConsumerState<NotificationCoordinator> {
  var _setupStarted = false;
  var _setupComplete = false;
  var _initialPushDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_setupLazy());
    });
  }

  Future<void> _setupLazy() async {
    if (_setupStarted || _setupComplete) return;
    _setupStarted = true;

    final env = AppEnv.fromEnvironment();
    final service = ref.read(notificationServiceProvider);

    await service.initialize(
      enablePush: env.enablePush && isFirebaseReady,
      enableLocal: true,
      onTap: _handleNotificationTap,
      onTokenRefresh: (token) =>
          ref.read(pushRegistrationProvider).register(pushToken: token),
    );

    if (!mounted) return;

    ref.read(notificationRealtimeProvider);

    final session = ref.read(sessionControllerProvider);
    if (SessionAuth.canCallProtectedApis(session)) {
      await ref.read(pushRegistrationProvider).register();
      _initialPushDone = true;
    }

    _setupComplete = true;
  }

  void _handleNotificationTap(Map<String, dynamic>? metadata) {
    final router = ref.read(goRouterProvider);
    final route = NotificationDeepLink.resolve(metadata: metadata);
    NotificationAnalytics.pushTap(route: route);
    router.go(route);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SessionState>(sessionControllerProvider, (previous, next) {
      final readyAuthed = SessionAuth.canCallProtectedApis(next);
      final wasReadyAuthed =
          previous != null && SessionAuth.canCallProtectedApis(previous);
      if (readyAuthed && !wasReadyAuthed) {
        unawaited(ref.read(pushRegistrationProvider).register());
      }
    });

    if (!_initialPushDone &&
        SessionAuth.canCallProtectedApis(ref.read(sessionControllerProvider))) {
      _initialPushDone = true;
      unawaited(ref.read(pushRegistrationProvider).register());
    }

    return widget.child;
  }
}
