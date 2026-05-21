import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_env.dart';
import '../../core/session/session_controller.dart';
import '../../core/session/session_state.dart';
import '../../routing/app_router.dart';
import '../../routing/app_routes.dart';
import 'fcm_background.dart';
import 'notification_realtime.dart';
import 'notification_service.dart';
import 'push_registration.dart';

class NotificationCoordinator extends ConsumerStatefulWidget {
  const NotificationCoordinator({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationCoordinator> createState() => _NotificationCoordinatorState();
}

class _NotificationCoordinatorState extends ConsumerState<NotificationCoordinator> {
  var _initialized = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_setup);
  }

  Future<void> _setup() async {
    if (_initialized) return;
    _initialized = true;

    final env = AppEnv.fromEnvironment();
    final service = ref.read(notificationServiceProvider);

    await service.initialize(
      enablePush: env.enablePush,
      enableLocal: true,
      onTap: _handleNotificationTap,
      onTokenRefresh: (token) =>
          ref.read(pushRegistrationProvider).register(pushToken: token),
    );

    ref.read(notificationRealtimeProvider);

    if (ref.read(sessionControllerProvider).isAuthenticated) {
      await ref.read(pushRegistrationProvider).register();
    }

    ref.listen<SessionState>(sessionControllerProvider, (previous, next) async {
      if (next.isAuthenticated && (previous == null || !previous.isAuthenticated)) {
        await ref.read(pushRegistrationProvider).register();
      }
    });
  }

  void _handleNotificationTap(Map<String, dynamic>? metadata) {
    final router = ref.read(goRouterProvider);
    final requestId = metadata?['serviceRequestId'];
    if (requestId is String && requestId.isNotEmpty) {
      router.go(AppRoutes.serviceRequestDetail(requestId));
      return;
    }
    router.go(AppRoutes.inbox);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

void registerFcmBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}
