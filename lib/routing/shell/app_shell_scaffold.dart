import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/navigation_service.dart';
import '../../core/offline/offline_status_banner.dart';
import '../../features/home/presentation/widgets/bottom_nav.dart';
import '../../features/home/presentation/widgets/drawer_menu.dart';
import '../../features/notifications/presentation/notification_providers.dart';
import '../../core/session/session_providers.dart';

class AppShellScaffold extends ConsumerWidget {
  const AppShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(sessionAuthenticatedProvider);
    final unread = isAuthenticated
        ? ref
              .watch(unreadNotificationCountProvider)
              .maybeWhen(data: (count) => count, orElse: () => 0)
        : 0;
    final isHomeTab = navigationShell.currentIndex == 0;

    return NavigationBackHandler(
      child: Scaffold(
        drawer: HomeDrawerMenu(navigationShell: navigationShell),
        body: OfflineStatusBanner(
          child: isHomeTab
              ? navigationShell
              : SafeArea(
                  top: true,
                  bottom: false,
                  child: navigationShell,
                ),
        ),
        bottomNavigationBar: HomeBottomNav(
          navigationShell: navigationShell,
          unreadCount: unread,
        ),
      ),
    );
  }
}
