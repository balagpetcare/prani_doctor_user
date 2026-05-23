import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/session/session_controller.dart';
import '../../../routing/app_routes.dart';
import '../notification_deeplink.dart';

/// Validates notification deep-link query params and navigates safely.
class NotificationDeepLinkPage extends ConsumerStatefulWidget {
  const NotificationDeepLinkPage({super.key});

  @override
  ConsumerState<NotificationDeepLinkPage> createState() =>
      _NotificationDeepLinkPageState();
}

class _NotificationDeepLinkPageState
    extends ConsumerState<NotificationDeepLinkPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_resolve);
  }

  Future<void> _resolve() async {
    if (!mounted) return;

    final session = ref.read(sessionControllerProvider);
    if (!session.isAuthenticated) {
      context.go(AppRoutes.login);
      return;
    }

    final params = GoRouterState.of(context).uri.queryParameters;
    final metadata = Map<String, dynamic>.from(params);
    final route = NotificationDeepLink.resolve(
      metadata: metadata,
      type: params['type'],
    );

    if (!mounted) return;
    context.go(route.isEmpty ? AppRoutes.inbox : route);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
