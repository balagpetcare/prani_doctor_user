import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'nav_guard.dart';
import '../features/auth/presentation/forgot_password_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/otp_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/onboarding/presentation/onboarding_providers.dart';
import '../features/auth/presentation/welcome_page.dart';
import '../features/boot/boot_controller.dart';
import '../features/boot/boot_state.dart';
import '../features/boot/presentation/boot_page.dart';
import '../features/milk/data/milk_dto.dart';
import '../features/feed/presentation/feed_analytics_page.dart';
import '../features/feed/presentation/feed_cost_page.dart';
import '../features/feed/presentation/feed_detail_page.dart';
import '../features/feed/presentation/feed_entry_form_page.dart';
import '../features/feed/presentation/feed_entry_page.dart';
import '../features/finance/presentation/finance_dashboard_page.dart';
import '../features/finance/presentation/finance_detail_page.dart';
import '../features/finance/presentation/finance_expense_form_page.dart';
import '../features/finance/presentation/finance_expense_page.dart';
import '../features/finance/presentation/finance_income_form_page.dart';
import '../features/finance/presentation/finance_income_page.dart';
import '../features/finance/presentation/finance_profit_page.dart';
import '../features/finance/presentation/finance_reports_page.dart';
import '../features/health/presentation/health_analytics_page.dart';
import '../features/health/presentation/health_dashboard_page.dart';
import '../features/health/presentation/health_detail_page.dart';
import '../features/health/presentation/health_form_page.dart';
import '../features/health/presentation/health_history_page.dart';
import '../features/health/presentation/health_timeline_page.dart';
import '../features/vaccine/presentation/vaccine_calendar_page.dart';
import '../features/vaccine/presentation/vaccine_dashboard_page.dart';
import '../features/vaccine/presentation/vaccine_detail_page.dart';
import '../features/vaccine/presentation/vaccine_form_page.dart';
import '../features/vaccine/presentation/vaccine_history_page.dart';
import '../features/vaccine/presentation/vaccine_reminder_page.dart';
import '../features/vaccine/presentation/vaccine_schedule_page.dart';
import '../features/treatment/presentation/treatment_dashboard_page.dart';
import '../features/treatment/presentation/treatment_detail_page.dart';
import '../features/treatment/presentation/treatment_follow_up_page.dart';
import '../features/treatment/presentation/treatment_form_page.dart';
import '../features/treatment/presentation/treatment_list_page.dart';
import '../features/treatment/presentation/treatment_medicine_plan_page.dart';
import '../features/treatment/presentation/treatment_prescription_page.dart';
import '../features/treatment/presentation/treatment_timeline_page.dart';
import '../features/support/presentation/support_attachment_viewer_page.dart';
import '../features/support/presentation/support_contact_page.dart';
import '../features/support/presentation/support_faq_page.dart';
import '../features/support/presentation/support_help_page.dart';
import '../features/support/presentation/support_home_page.dart';
import '../features/support/presentation/support_ticket_create_page.dart';
import '../features/support/presentation/support_ticket_detail_page.dart';
import '../features/support/presentation/support_ticket_list_page.dart';
import '../features/ai/presentation/ai_chat_page.dart';
import '../features/ai/presentation/ai_history_page.dart';
import '../features/ai/presentation/ai_home_page.dart';
import '../features/ai/presentation/ai_result_page.dart';
import '../features/ai/presentation/ai_settings_page.dart';
import '../features/ai/presentation/ai_voice_input_page.dart';
import '../features/milk/presentation/milk_charts_page.dart';
import '../features/milk/presentation/milk_daily_summary_page.dart';
import '../features/milk/presentation/milk_detail_page.dart';
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
import '../features/farm/presentation/farm_settings_page.dart';
import '../features/home/home_page.dart';
import '../features/home/presentation/pages/community_page.dart';
import '../features/home/presentation/pages/marketplace_page.dart';
import '../features/home/presentation/pages/orders_page.dart';
import '../features/search/presentation/universal_search_page.dart';
import '../features/inbox/inbox_page.dart';
import '../features/services/services_page.dart';
import '../features/doctors/presentation/book_consultation_page.dart';
import '../features/doctors/presentation/doctor_detail_page.dart';
import '../features/notifications/presentation/notification_center_page.dart';
import '../features/notifications/presentation/notification_deeplink_page.dart';
import '../features/notifications/presentation/notification_detail_page.dart';
import '../features/notifications/presentation/notification_permission_page.dart';
import '../features/notifications/presentation/notification_settings_page.dart';
import '../features/settings/presentation/privacy_page.dart';
import '../features/settings/presentation/terms_page.dart';
import '../features/settings/presentation/settings_account_page.dart';
import '../features/settings/presentation/settings_personal_info_page.dart';
import '../features/settings/presentation/settings_preferences_page.dart';
import '../features/settings/presentation/settings_app_page.dart';
import '../features/settings/presentation/settings_language_page.dart';
import '../features/settings/presentation/settings_theme_page.dart';
import '../features/settings/presentation/settings_about_page.dart';
import '../features/settings/presentation/connection_check_page.dart';
import '../features/settings/presentation/settings_data_sync_page.dart';
import '../features/settings/settings_page.dart';
import '../features/profile/presentation/change_password_page.dart';
import '../features/profile/presentation/profile_address_page.dart';
import '../features/profile/presentation/profile_completion_page.dart';
import '../features/profile/presentation/profile_appearance_page.dart';
import '../features/profile/presentation/profile_language_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/service_requests/presentation/service_request_detail_page.dart';
import '../features/service_requests/presentation/service_request_history_page.dart';
import 'app_routes.dart';
import 'shell/app_shell_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Notifies [GoRouter] after frame — avoids redirect during widget rebuild.
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    void scheduleNotify() {
      if (_disposed || _notifyPending) return;
      _notifyPending = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notifyPending = false;
        if (!_disposed) {
          NavLog.nav('refresh redirect');
          notifyListeners();
        }
      });
    }

    _ref.listen<NavPhase>(navPhaseProvider, (_, _) => scheduleNotify());
    _ref.listen<BootState>(bootControllerProvider, (prev, next) {
      if (prev?.isReady != next.isReady ||
          prev?.forceUpdateRequired != next.forceUpdateRequired ||
          prev?.maintenanceActive != next.maintenanceActive ||
          prev?.optionalUpdatePending != next.optionalUpdatePending ||
          prev?.hasError != next.hasError) {
        scheduleNotify();
      }
    });
    _ref.listen(onboardingCompletedProvider, (_, _) => scheduleNotify());
  }

  final Ref _ref;
  bool _notifyPending = false;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  final notifier = RouterNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});

final goRouterProvider = Provider<GoRouter>((ref) {
  ref.keepAlive();
  final notifier = ref.read(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.boot,
    refreshListenable: notifier,
    redirect: (context, state) => resolveRedirect(ref: ref, state: state),
    routes: [
      GoRoute(
        path: AppRoutes.boot,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'boot',
        builder: (context, state) => const BootPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
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
        builder: (context, state) =>
            OtpPage(phone: state.uri.queryParameters['phone']),
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
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  child: HomePage(
                    refreshOnOpen:
                        state.uri.queryParameters['refresh'] == 'true',
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'ai-chat',
                    name: 'aiChat',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) =>
                        AiChatPage(initialPrompt: state.extra as String?),
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
                pageBuilder: (context, state) =>
                    const NoTransitionPage<void>(child: ServicesPage()),
                routes: [
                  GoRoute(
                    path: 'doctor/:id',
                    name: 'doctorDetail',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) =>
                        DoctorDetailPage(doctorId: state.pathParameters['id']!),
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
                pageBuilder: (context, state) =>
                    const NoTransitionPage<void>(child: InboxPage()),
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
                pageBuilder: (context, state) =>
                    const NoTransitionPage<void>(child: SettingsPage()),
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
                        builder: (context, state) =>
                            const ProfileAppearancePage(),
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
                        builder: (context, state) =>
                            const ProfileLanguagePage(),
                      ),
                      GoRoute(
                        path: 'complete',
                        name: 'settingsProfileComplete',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) =>
                            const ProfileCompletionPage(),
                      ),
                      GoRoute(
                        path: 'change-password',
                        name: 'settingsProfileChangePassword',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) => const ChangePasswordPage(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'notifications',
                    name: 'settingsNotifications',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) =>
                        const NotificationSettingsPage(),
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
                  GoRoute(
                    path: 'account',
                    name: 'settingsAccount',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const SettingsAccountPage(),
                    routes: [
                      GoRoute(
                        path: 'personal-info',
                        name: 'settingsPersonalInfo',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) =>
                            const SettingsPersonalInfoPage(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'preferences',
                    name: 'settingsPreferences',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) =>
                        const SettingsPreferencesPage(),
                  ),
                  GoRoute(
                    path: 'app',
                    name: 'settingsApp',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const SettingsAppPage(),
                  ),
                  GoRoute(
                    path: 'language',
                    name: 'settingsLanguage',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const SettingsLanguagePage(),
                  ),
                  GoRoute(
                    path: 'theme',
                    name: 'settingsTheme',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const SettingsThemePage(),
                  ),
                  GoRoute(
                    path: 'about',
                    name: 'settingsAbout',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const SettingsAboutPage(),
                  ),
                  GoRoute(
                    path: 'data-sync',
                    name: 'settingsDataSync',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const SettingsDataSyncPage(),
                  ),
                  GoRoute(
                    path: 'connection',
                    name: 'settingsConnection',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const ConnectionCheckPage(),
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
            builder: (context, state) =>
                FarmDetailPage(farmId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'edit',
                name: 'farmEdit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) =>
                    FarmFormPage(farmId: state.pathParameters['id']),
              ),
              GoRoute(
                path: 'settings',
                name: 'farmSettings',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) =>
                    FarmSettingsPage(farmId: state.pathParameters['id']!),
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
            builder: (context, state) =>
                AnimalDetailPage(animalId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'edit',
                name: 'animalEdit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) =>
                    AnimalFormPage(animalId: state.pathParameters['id']),
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
            builder: (context, state) =>
                BatchDetailPage(batchId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'edit',
                name: 'batchEdit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) =>
                    BatchFormPage(batchId: state.pathParameters['id']),
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
            path: ':id',
            name: 'milkDetail',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) =>
                MilkDetailPage(recordId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'edit',
                name: 'milkEdit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) =>
                    MilkEntryFormPage(recordId: state.pathParameters['id']),
              ),
            ],
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
            path: 'analytics',
            name: 'feedAnalytics',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const FeedAnalyticsPage(),
          ),
          GoRoute(
            path: ':id',
            name: 'feedDetail',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) =>
                FeedDetailPage(recordId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'edit',
                name: 'feedEdit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) =>
                    FeedEntryFormPage(recordId: state.pathParameters['id']),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.finance,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'finance',
        builder: (context, state) => const FinanceDashboardPage(),
      ),
      GoRoute(
        path: AppRoutes.financeReports,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'financeReports',
        builder: (context, state) => const FinanceReportsPage(),
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
            path: ':id',
            name: 'financeExpenseDetail',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => FinanceDetailPage(
              recordId: state.pathParameters['id']!,
              isExpense: true,
            ),
            routes: [
              GoRoute(
                path: 'edit',
                name: 'financeExpenseEdit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => FinanceExpenseFormPage(
                  recordId: state.pathParameters['id'],
                ),
              ),
            ],
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
            path: ':id',
            name: 'financeIncomeDetail',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => FinanceDetailPage(
              recordId: state.pathParameters['id']!,
              isExpense: false,
            ),
            routes: [
              GoRoute(
                path: 'edit',
                name: 'financeIncomeEdit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) =>
                    FinanceIncomeFormPage(recordId: state.pathParameters['id']),
              ),
            ],
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
        builder: (context, state) => const HealthDashboardPage(),
        routes: [
          GoRoute(
            path: 'history',
            name: 'healthHistory',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const HealthHistoryPage(),
          ),
          GoRoute(
            path: 'records',
            name: 'healthRecords',
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
            path: 'analytics',
            name: 'healthAnalytics',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const HealthAnalyticsPage(),
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
            builder: (context, state) =>
                HealthDetailPage(recordId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'edit',
                name: 'healthEdit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) =>
                    HealthFormPage(recordId: state.pathParameters['id']),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.vaccines,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'vaccines',
        builder: (context, state) => const VaccineDashboardPage(),
        routes: [
          GoRoute(
            path: 'schedule',
            name: 'vaccineSchedule',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const VaccineSchedulePage(),
          ),
          GoRoute(
            path: 'history',
            name: 'vaccineHistory',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const VaccineHistoryPage(),
          ),
          GoRoute(
            path: 'calendar',
            name: 'vaccineCalendar',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const VaccineCalendarPage(),
          ),
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
            path: ':id',
            name: 'vaccineDetail',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) =>
                VaccineDetailPage(recordId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'edit',
                name: 'vaccineEdit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) =>
                    VaccineFormPage(recordId: state.pathParameters['id']),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.treatments,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'treatments',
        builder: (context, state) => const TreatmentDashboardPage(),
        routes: [
          GoRoute(
            path: 'list',
            name: 'treatmentList',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const TreatmentListPage(),
          ),
          GoRoute(
            path: 'timeline',
            name: 'treatmentTimeline',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const TreatmentTimelinePage(),
          ),
          GoRoute(
            path: 'medicine-plan',
            name: 'treatmentMedicinePlan',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const TreatmentMedicinePlanPage(),
          ),
          GoRoute(
            path: 'follow-up',
            name: 'treatmentFollowUp',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const TreatmentFollowUpPage(),
          ),
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
            builder: (context, state) =>
                TreatmentDetailPage(treatmentId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'edit',
                name: 'treatmentEdit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) =>
                    TreatmentFormPage(recordId: state.pathParameters['id']),
              ),
              GoRoute(
                path: 'prescription',
                name: 'treatmentPrescription',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => TreatmentPrescriptionPage(
                  treatmentId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.notifications,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'notifications',
        builder: (context, state) => const NotificationCenterPage(),
        routes: [
          GoRoute(
            path: 'permission',
            name: 'notificationPermission',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const NotificationPermissionPage(),
          ),
          GoRoute(
            path: 'open',
            name: 'notificationDeepLink',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const NotificationDeepLinkPage(),
          ),
          GoRoute(
            path: ':id',
            name: 'notificationDetail',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => NotificationDetailPage(
              notificationId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.ai,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'aiHome',
        builder: (context, state) => const AiHomePage(),
      ),
      GoRoute(
        path: AppRoutes.aiHistory,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'aiHistory',
        builder: (context, state) => const AiHistoryPage(),
      ),
      GoRoute(
        path: AppRoutes.aiSettings,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'aiSettings',
        builder: (context, state) => const AiSettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.aiResult,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'aiResult',
        builder: (context, state) =>
            AiResultPage(result: triageResultFromExtra(state.extra)),
      ),
      GoRoute(
        path: AppRoutes.support,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'supportHome',
        builder: (context, state) => const SupportHomePage(),
      ),
      GoRoute(
        path: AppRoutes.marketplace,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'marketplace',
        builder: (context, state) => const MarketplacePage(),
      ),
      GoRoute(
        path: AppRoutes.community,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'community',
        builder: (context, state) => const CommunityPage(),
      ),
      GoRoute(
        path: AppRoutes.orders,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'orders',
        builder: (context, state) => const OrdersPage(),
      ),
      GoRoute(
        path: AppRoutes.search,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'search',
        builder: (context, state) {
          final voice = state.uri.queryParameters['voice'] == '1';
          return UniversalSearchPage(startVoice: voice);
        },
      ),
      GoRoute(
        path: AppRoutes.supportFaq,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'supportFaq',
        builder: (context, state) => const SupportFaqPage(),
      ),
      GoRoute(
        path: AppRoutes.supportContact,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'supportContact',
        builder: (context, state) => const SupportContactPage(),
      ),
      GoRoute(
        path: AppRoutes.supportAttachmentView,
        parentNavigatorKey: _rootNavigatorKey,
        name: 'supportAttachmentView',
        builder: (context, state) {
          final page = supportAttachmentViewerFromState(state);
          return page ?? const SupportHomePage();
        },
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
            builder: (context, state) =>
                SupportTicketDetailPage(ticketId: state.pathParameters['id']!),
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
