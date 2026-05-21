import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../app_routes.dart';

class AppShellScaffold extends StatelessWidget {
  const AppShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  l10n.drawerTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: Text(l10n.navHome),
              onTap: () {
                navigationShell.goBranch(0, initialLocation: true);
                context.go(AppRoutes.home);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.medical_services_outlined),
              title: Text(l10n.navServices),
              onTap: () {
                navigationShell.goBranch(1, initialLocation: true);
                context.go(AppRoutes.services);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.inbox_outlined),
              title: Text(l10n.navInbox),
              onTap: () {
                navigationShell.goBranch(2, initialLocation: true);
                context.go(AppRoutes.inbox);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: Text(l10n.navSettings),
              onTap: () {
                navigationShell.goBranch(3, initialLocation: true);
                context.go(AppRoutes.settings);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
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
            icon: const Icon(Icons.inbox_outlined),
            selectedIcon: const Icon(Icons.inbox),
            label: l10n.navInbox,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}

