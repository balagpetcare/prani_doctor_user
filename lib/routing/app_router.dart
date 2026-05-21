import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/session/session_controller.dart';
import '../core/session/session_state.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/home/home_page.dart';
import '../features/inbox/inbox_page.dart';
import '../features/services/services_page.dart';
import '../features/doctors/presentation/book_consultation_page.dart';
import '../features/doctors/presentation/doctor_detail_page.dart';
import '../features/settings/settings_page.dart';
import '../features/profile/presentation/profile_edit_page.dart';
import '../features/service_requests/presentation/service_request_detail_page.dart';
import '../features/service_requests/presentation/service_request_history_page.dart';
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
      final isAuthRoute = loc == AppRoutes.login || loc == AppRoutes.register;
      if (!session.isAuthenticated && !isAuthRoute) {
        return AppRoutes.login;
      }
      if (session.isAuthenticated && isAuthRoute) {
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
                routes: [
                  GoRoute(
                    path: 'doctor/:id',
                    name: 'doctorDetail',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => DoctorDetailPage(
                      doctorId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'book',
                        name: 'bookConsultation',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) => BookConsultationPage(
                          doctorId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                ],
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
                routes: [
                  GoRoute(
                    path: 'request/:id',
                    name: 'serviceRequestDetail',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => ServiceRequestDetailPage(
                      requestId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'history',
                        name: 'serviceRequestHistory',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) => ServiceRequestHistoryPage(
                          requestId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                ],
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
                routes: [
                  GoRoute(
                    path: 'profile',
                    name: 'settingsProfile',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const ProfileEditPage(),
                  ),
                ],
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
      GoRoute(
        path: AppRoutes.register,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
    ],
  );
});
