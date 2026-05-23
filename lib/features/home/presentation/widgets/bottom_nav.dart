import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    super.key,
    required this.navigationShell,
    required this.unreadCount,
  });

  final StatefulNavigationShell navigationShell;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) {
        navigationShell.goBranch(index, initialLocation: true);
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: l10n.navHome,
        ),
        NavigationDestination(
          icon: const Icon(Icons.medical_services_outlined),
          selectedIcon: const Icon(Icons.medical_services),
          label: l10n.navServices,
        ),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text('$unreadCount'),
            child: const Icon(Icons.inbox_outlined),
          ),
          selectedIcon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text('$unreadCount'),
            child: const Icon(Icons.inbox),
          ),
          label: l10n.navInbox,
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: l10n.navSettings,
        ),
      ],
    );
  }
}
