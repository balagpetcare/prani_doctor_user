import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/session/session_controller.dart';
import '../core/session/session_state.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/home/home_page.dart';
import '../features/inbox/inbox_page.dart';
import '../features/services/services_page.dart';
import '../features/settings/settings_page.dart';
import 'app_routes.dart';
import 'shell/app_shell_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Notifies [GoRouter] when [SessionState] changes (for redirects).
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen<SessionState>(
      sessionControllerProvider,
      (_, next) => notifyListeners(),
    );
  }

  final Ref _ref;
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) => RouterNotifier(ref));

final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);
  final session = ref.watch(sessionControllerProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    refreshListenable: notifier,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final loggingIn = loc == AppRoutes.login;
      if (!session.isAuthenticated && !loggingIn) {
        return AppRoutes.login;
      }
      if (session.isAuthenticated && loggingIn) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShellScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: HomePage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.services,
                name: 'services',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: ServicesPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.inbox,
                name: 'inbox',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: InboxPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                name: 'settings',
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: SettingsPage(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.login,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
    ],
  );
});
