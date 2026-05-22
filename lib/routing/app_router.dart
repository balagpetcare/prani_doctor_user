import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/session/session_controller.dart';
import '../core/session/session_state.dart';
import '../features/auth/presentation/auth_providers.dart';
import '../features/auth/presentation/forgot_password_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/otp_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/auth/presentation/welcome_page.dart';
import '../features/boot/boot_controller.dart';
import '../features/boot/boot_state.dart';
import '../features/boot/presentation/boot_page.dart';
import '../features/milk/data/milk_dto.dart';
import '../features/feed/presentation/feed_cost_page.dart';
import '../features/feed/presentation/feed_entry_form_page.dart';
import '../features/feed/presentation/feed_entry_page.dart';
import '../features/finance/presentation/finance_expense_form_page.dart';
import '../features/finance/presentation/finance_expense_page.dart';
import '../features/finance/presentation/finance_income_form_page.dart';
import '../features/finance/presentation/finance_income_page.dart';
import '../features/finance/presentation/finance_profit_page.dart';
import '../features/health/presentation/health_detail_page.dart';
import '../features/health/presentation/health_form_page.dart';
import '../features/health/presentation/health_history_page.dart';
import '../features/health/presentation/health_timeline_page.dart';
import '../features/vaccine/presentation/vaccine_form_page.dart';
import '../features/vaccine/presentation/vaccine_reminder_page.dart';
import '../features/vaccine/presentation/vaccine_schedule_page.dart';
import '../features/treatment/presentation/treatment_detail_page.dart';
import '../features/treatment/presentation/treatment_form_page.dart';
import '../features/treatment/presentation/treatment_list_page.dart';
import '../features/support/presentation/support_help_page.dart';
import '../features/support/presentation/support_ticket_create_page.dart';
import '../features/support/presentation/support_ticket_detail_page.dart';
import '../features/support/presentation/support_ticket_list_page.dart';
import '../features/ai/presentation/ai_chat_page.dart';
import '../features/ai/presentation/ai_voice_input_page.dart';
import '../features/milk/presentation/milk_charts_page.dart';
import '../features/milk/presentation/milk_daily_summary_page.dart';
import '../features/milk/presentation/milk_entry_form_page.dart';
import '../features/milk/presentation/milk_entry_page.dart';
import '../features/batches/presentation/batch_detail_page.dart';
import '../features/batches/presentation/batch_form_page.dart';
import '../features/batches/presentation/batch_list_page.dart';
import '../features/animals/presentation/animal_detail_page.dart';
import '../features/animals/presentation/animal_form_page.dart';
import '../features/animals/presentation/animal_list_page.dart';
import '../features/farm/presentation/farm_detail_page.dart';
import '../features/farm/presentation/farm_form_page.dart';
import '../features/farm/presentation/farm_list_page.dart';
import '../features/home/home_page.dart';
import '../features/inbox/inbox_page.dart';
import '../features/services/services_page.dart';
import '../features/doctors/presentation/book_consultation_page.dart';
import '../features/doctors/presentation/doctor_detail_page.dart';
import '../features/notifications/presentation/notification_settings_page.dart';
import '../features/settings/presentation/privacy_page.dart';
import '../features/settings/presentation/terms_page.dart';
import '../features/settings/settings_page.dart';
import '../features/profile/presentation/profile_address_page.dart';
import '../features/profile/presentation/profile_edit_page.dart';
import '../features/profile/presentation/profile_language_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/service_requests/presentation/service_request_detail_page.dart';
import '../features/service_requests/presentation/service_request_history_page.dart';
import 'app_routes.dart';
import 'shell/app_shell_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Notifies [GoRouter] when session or boot state changes (for redirects).
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen<SessionState>(
      sessionControllerProvider,
      (_, __) => notifyListeners(),
    );
    _ref.listen<BootState>(
      bootControllerProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref _ref;
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) => RouterNotifier(ref));

final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);
  final session = ref.watch(sessionControllerProvider);
  final boot = ref.watch(bootControllerProvider);
  final welcomeSeenAsync = ref.watch(welcomeSeenProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.boot,
    refreshListenable: notifier,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isBootRoute = loc == AppRoutes.boot;
      final isWelcomeRoute = loc == AppRoutes.welcome;
      final isAuthRoute = _isPublicAuthRoute(loc);

      if (!boot.isReady) {
        if (boot.forceUpdateRequired || boot.hasError) {
          return isBootRoute ? null : AppRoutes.boot;
        }
        return isBootRoute ? null : AppRoutes.boot;
      }

      if (isBootRoute) {
        if (session.isAuthenticated) return AppRoutes.home;
        return _unauthenticatedEntry(ref, welcomeSeenAsync);
      }

      if (!session.isAuthenticated) {
        if (isAuthRoute || isWelcomeRoute) return null;
        return _unauthenticatedEntry(ref, welcomeSeenAsync);
      }

      if (session.isAuthenticated && isAuthRoute) {
        return AppRoutes.home;
      }
      if (session.isAuthenticated && isWelcomeRoute) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.boot,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'boot',
        builder: (context, state) => const BootPage(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'otp',
        builder: (context, state) => OtpPage(
          phone: state.uri.queryParameters['phone'],
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
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
                routes: [
                  GoRoute(
                    path: 'ai-chat',
                    name: 'aiChat',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => AiChatPage(
                      initialPrompt: state.extra as String?,
                    ),
                    routes: [
                      GoRoute(
                        path: 'voice',
                        name: 'aiVoiceInput',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) => const AiVoiceInputPage(),
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
                    builder: (context, state) => const ProfilePage(),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        name: 'settingsProfileEdit',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) => const ProfileEditPage(),
                      ),
                      GoRoute(
                        path: 'address',
                        name: 'settingsProfileAddress',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) => const ProfileAddressPage(),
                      ),
                      GoRoute(
                        path: 'language',
                        name: 'settingsProfileLanguage',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) => const ProfileLanguagePage(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'notifications',
                    name: 'settingsNotifications',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const NotificationSettingsPage(),
                  ),
                  GoRoute(
                    path: 'privacy',
                    name: 'settingsPrivacy',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const PrivacyPage(),
                  ),
                  GoRoute(
                    path: 'terms',
                    name: 'settingsTerms',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const TermsPage(),
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
      GoRoute(
        path: AppRoutes.farms,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'farms',
        builder: (context, state) => const FarmListPage(),
        routes: [
          GoRoute(
            path: 'create',
            name: 'farmCreate',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const FarmFormPage(),
          ),
          GoRoute(
            path: ':id',
            name: 'farmDetail',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => FarmDetailPage(
              farmId: state.pathParameters['id']!,
            ),
            routes: [
              GoRoute(
                path: 'edit',
                name: 'farmEdit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => FarmFormPage(
                  farmId: state.pathParameters['id'],
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.animals,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'animals',
        builder: (context, state) => const AnimalListPage(),
        routes: [
          GoRoute(
            path: 'create',
            name: 'animalCreate',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const AnimalFormPage(),
          ),
          GoRoute(
            path: ':id',
            name: 'animalDetail',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => AnimalDetailPage(
              animalId: state.pathParameters['id']!,
            ),
            routes: [
              GoRoute(
                path: 'edit',
                name: 'animalEdit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => AnimalFormPage(
                  animalId: state.pathParameters['id'],
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.batches,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'batches',
        builder: (context, state) => const BatchListPage(),
        routes: [
          GoRoute(
            path: 'create',
            name: 'batchCreate',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const BatchFormPage(),
          ),
          GoRoute(
            path: ':id',
            name: 'batchDetail',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => BatchDetailPage(
              batchId: state.pathParameters['id']!,
            ),
            routes: [
              GoRoute(
                path: 'edit',
                name: 'batchEdit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => BatchFormPage(
                  batchId: state.pathParameters['id'],
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.milk,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'milk',
        builder: (context, state) => const MilkEntryPage(),
        routes: [
          GoRoute(
            path: 'create',
            name: 'milkCreate',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final sessionParam = state.uri.queryParameters['session'];
              MilkSession? session;
              if (sessionParam == 'evening') session = MilkSession.evening;
              if (sessionParam == 'morning') session = MilkSession.morning;
              return MilkEntryFormPage(initialSession: session);
            },
          ),
          GoRoute(
            path: 'summary',
            name: 'milkSummary',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const MilkDailySummaryPage(),
          ),
          GoRoute(
            path: 'charts',
            name: 'milkCharts',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const MilkChartsPage(),
          ),
          GoRoute(
            path: ':id/edit',
            name: 'milkEdit',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => MilkEntryFormPage(
              recordId: state.pathParameters['id'],
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.feeds,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'feeds',
        builder: (context, state) => const FeedEntryPage(),
        routes: [
          GoRoute(
            path: 'create',
            name: 'feedCreate',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const FeedEntryFormPage(),
          ),
          GoRoute(
            path: 'cost',
            name: 'feedCost',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const FeedCostPage(),
          ),
          GoRoute(
            path: ':id/edit',
            name: 'feedEdit',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => FeedEntryFormPage(
              recordId: state.pathParameters['id'],
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.financeExpenses,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'financeExpenses',
        builder: (context, state) => const FinanceExpensePage(),
        routes: [
          GoRoute(
            path: 'create',
            name: 'financeExpenseCreate',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const FinanceExpenseFormPage(),
          ),
          GoRoute(
            path: ':id/edit',
            name: 'financeExpenseEdit',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => FinanceExpenseFormPage(
              recordId: state.pathParameters['id'],
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.financeIncome,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'financeIncome',
        builder: (context, state) => const FinanceIncomePage(),
        routes: [
          GoRoute(
            path: 'create',
            name: 'financeIncomeCreate',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const FinanceIncomeFormPage(),
          ),
          GoRoute(
            path: ':id/edit',
            name: 'financeIncomeEdit',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => FinanceIncomeFormPage(
              recordId: state.pathParameters['id'],
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.financeProfit,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'financeProfit',
        builder: (context, state) => const FinanceProfitPage(),
      ),
      GoRoute(
        path: '/health',
        parentNavigatorKey: _rootNavigatorKey,
        name: 'health',
        redirect: (context, state) {
          if (state.uri.path == '/health') return AppRoutes.healthHistory;
          return null;
        },
        routes: [
          GoRoute(
            path: 'history',
            name: 'healthHistory',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const HealthHistoryPage(),
          ),
          GoRoute(
            path: 'timeline',
            name: 'healthTimeline',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const HealthTimelinePage(),
          ),
          GoRoute(
            path: 'create',
            name: 'healthCreate',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const HealthFormPage(),
          ),
          GoRoute(
            path: ':id',
            name: 'healthDetail',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => HealthDetailPage(
              recordId: state.pathParameters['id']!,
            ),
            routes: [
              GoRoute(
                path: 'edit',
                name: 'healthEdit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => HealthFormPage(
                  recordId: state.pathParameters['id'],
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.vaccines,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'vaccines',
        builder: (context, state) => const VaccineSchedulePage(),
        routes: [
          GoRoute(
            path: 'reminders',
            name: 'vaccineReminders',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const VaccineReminderPage(),
          ),
          GoRoute(
            path: 'create',
            name: 'vaccineCreate',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const VaccineFormPage(),
          ),
          GoRoute(
            path: ':id/edit',
            name: 'vaccineEdit',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => VaccineFormPage(
              recordId: state.pathParameters['id'],
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.treatments,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'treatments',
        builder: (context, state) => const TreatmentListPage(),
        routes: [
          GoRoute(
            path: 'create',
            name: 'treatmentCreate',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const TreatmentFormPage(),
          ),
          GoRoute(
            path: ':id',
            name: 'treatmentDetail',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => TreatmentDetailPage(
              treatmentId: state.pathParameters['id']!,
            ),
            routes: [
              GoRoute(
                path: 'edit',
                name: 'treatmentEdit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => TreatmentFormPage(
                  recordId: state.pathParameters['id'],
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.supportTickets,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'supportTickets',
        builder: (context, state) => const SupportTicketListPage(),
        routes: [
          GoRoute(
            path: 'create',
            name: 'supportTicketCreate',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const SupportTicketCreatePage(),
          ),
          GoRoute(
            path: ':id',
            name: 'supportTicketDetail',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => SupportTicketDetailPage(
              ticketId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.supportHelp,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'supportHelp',
        builder: (context, state) => const SupportHelpPage(),
      ),
    ],
  );
});

bool _isPublicAuthRoute(String location) {
  return location == AppRoutes.login ||
      location == AppRoutes.register ||
      location == AppRoutes.otp ||
      location == AppRoutes.forgotPassword;
}

String _unauthenticatedEntry(Ref ref, AsyncValue<bool> welcomeSeenAsync) {
  final seen = welcomeSeenAsync.maybeWhen(data: (value) => value, orElse: () => false);
  return seen ? AppRoutes.login : AppRoutes.welcome;
}
