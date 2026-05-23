import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pranidoctor_user/features/animals/presentation/animal_providers.dart';
import 'package:pranidoctor_user/features/finance/data/finance_dto.dart';
import 'package:pranidoctor_user/features/finance/presentation/finance_providers.dart';
import 'package:pranidoctor_user/features/home/data/dashboard_context_dto.dart';
import 'package:pranidoctor_user/features/home/home_page.dart';
import 'package:pranidoctor_user/features/home/presentation/home_providers.dart';
import 'package:pranidoctor_user/features/home/presentation/models/home_section_models.dart';
import 'package:pranidoctor_user/features/home/presentation/providers/home_community_provider.dart';
import 'package:pranidoctor_user/features/home/presentation/providers/home_marketplace_provider.dart';
import 'package:pranidoctor_user/features/home/presentation/providers/home_section_providers.dart';
import 'package:pranidoctor_user/features/support/data/support_dto.dart';
import 'package:pranidoctor_user/features/support/presentation/support_providers.dart';
import 'package:pranidoctor_user/features/notifications/presentation/notification_providers.dart';
import 'package:pranidoctor_user/features/profile/data/mobile_me_dto.dart';
import 'package:pranidoctor_user/features/profile/presentation/profile_providers.dart';
import 'package:pranidoctor_user/features/service_requests/data/service_request_repository.dart';
import 'package:pranidoctor_user/features/vaccine/data/vaccine_dto.dart';
import 'package:pranidoctor_user/features/vaccine/presentation/vaccine_providers.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomePage', () {
    testWidgets('shows summary and greeting when dashboard loads', (
      tester,
    ) async {
      const context = DashboardContext(
        dashboardType: DashboardType.general,
        user: DashboardContextUser(
          id: '1',
          name: 'Karim',
          phone: '+8801712345678',
          email: 'k@example.com',
        ),
        farmSummary: FarmSummary(
          animalCount: 3,
          activeAnimalCount: 2,
          primaryVillageId: 'v1',
          primaryVillageLabelBn: 'Test Village',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardProvider.overrideWith(
              () => _StubDashboardNotifier(context),
            ),
            dashboardMetricsProvider.overrideWith(
              (ref) async => const DashboardMetrics(
                totalFarms: 1,
                totalAnimals: 3,
                activeAppointments: 2,
                unreadNotifications: 1,
              ),
            ),
            mobileMeProvider.overrideWith(_StubMobileMeNotifier.new),
            homeAnimalSummaryProvider.overrideWith(
              (ref) async => const HomeAnimalSummaryMetrics(
                totalAnimals: 3,
                vaccineDue: 0,
                activeTreatments: 0,
                tasks: 0,
              ),
            ),
            homeHealthTasksProvider.overrideWith((ref) async => const []),
            homeDoctorsPreviewProvider.overrideWith((ref) async => const []),
            vaccineReminderProvider.overrideWith(
              (ref) async =>
                  const VaccineRemindersData(overdue: [], upcoming: []),
            ),
            serviceCategoriesProvider.overrideWith((ref) async => const []),
            homeMarketplacePreviewProvider.overrideWith(
              (ref) async => HomeMarketplacePreview.empty,
            ),
            homeCommunityPreviewProvider.overrideWith(
              (ref) async => HomeCommunityPreview.empty,
            ),
            supportHelpProvider.overrideWith(_StubSupportHelpNotifier.new),
            financeReportsProvider.overrideWith(
              (ref) async => const FinanceReportsData(
                from: '2026-01-01',
                to: '2026-01-31',
                totalIncomeBdt: 0,
                totalExpenseBdt: 0,
                profitBdt: 0,
                expenseByCategory: [],
                incomeBySource: [],
                export: FinanceExportHooks(
                  csvPath: '',
                  pdfPath: '',
                  note: '',
                ),
              ),
            ),
            animalListProvider.overrideWith(_StubAnimalListNotifier.new),
            notificationListProvider.overrideWith(
              _StubNotificationListNotifier.new,
            ),
            dashboardAppointmentsProvider.overrideWith(
              (ref) async => DashboardAppointmentsSection.empty,
            ),
            dashboardActivityProvider.overrideWith(
              (ref) async => DashboardActivitySection.empty,
            ),
            dashboardHealthAlertsProvider.overrideWith(
              (ref) async => DashboardHealthAlertsSection.empty,
            ),
            dashboardPollProvider.overrideWith(_StubPollNotifier.new),
            unreadNotificationCountProvider.overrideWith(
              _StubUnreadNotifier.new,
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: HomePage()),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Karim'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Summary'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Summary'), findsOneWidget);
      expect(find.text('3'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Upcoming health tasks'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Upcoming health tasks'), findsOneWidget);
    });

    testWidgets('shows skeleton while loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardProvider.overrideWith(_LoadingDashboardNotifier.new),
            dashboardPollProvider.overrideWith(_StubPollNotifier.new),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: HomePage()),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(HomePage), findsOneWidget);
    });
  });
}

class _StubDashboardNotifier extends DashboardNotifier {
  _StubDashboardNotifier(this._value);

  final DashboardContext _value;

  @override
  Future<DashboardContext?> build() async => _value;
}

class _LoadingDashboardNotifier extends DashboardNotifier {
  @override
  Future<DashboardContext?> build() async {
    await Completer<void>().future;
    return null;
  }
}

class _StubPollNotifier extends DashboardPollNotifier {
  @override
  int build() => 0;
}

class _StubUnreadNotifier extends UnreadNotificationCountNotifier {
  @override
  Future<int> build() async => 0;
}

class _StubAnimalListNotifier extends AnimalListNotifier {
  @override
  Future<AnimalListState> build() async =>
      const AnimalListState(animals: [], total: 0);
}

class _StubNotificationListNotifier extends NotificationListNotifier {
  @override
  Future<NotificationListState> build() async => const NotificationListState();
}

class _StubMobileMeNotifier extends MobileMeNotifier {
  @override
  Future<MobileMeDto?> build() async => null;
}

class _StubSupportHelpNotifier extends SupportHelpNotifier {
  @override
  Future<SupportHelpData> build() async => const SupportHelpData();
}
