import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pranidoctor_user/features/animals/data/animal_dto.dart';
import 'package:pranidoctor_user/features/animals/presentation/animal_providers.dart';
import 'package:pranidoctor_user/features/home/data/dashboard_context_dto.dart';
import 'package:pranidoctor_user/features/home/home_page.dart';
import 'package:pranidoctor_user/features/home/presentation/home_providers.dart';
import 'package:pranidoctor_user/features/home/presentation/models/home_section_models.dart';
import 'package:pranidoctor_user/features/home/presentation/providers/home_community_provider.dart';
import 'package:pranidoctor_user/features/home/presentation/providers/home_marketplace_provider.dart';
import 'package:pranidoctor_user/features/home/presentation/providers/home_section_providers.dart';
import 'package:pranidoctor_user/features/notifications/presentation/notification_providers.dart';
import 'package:pranidoctor_user/features/profile/data/mobile_me_dto.dart';
import 'package:pranidoctor_user/features/profile/presentation/profile_providers.dart';
import 'package:pranidoctor_user/features/service_requests/data/service_request_repository.dart';
import 'package:pranidoctor_user/features/support/data/support_dto.dart';
import 'package:pranidoctor_user/features/support/presentation/support_providers.dart';
import 'package:pranidoctor_user/features/vaccine/data/vaccine_dto.dart';
import 'package:pranidoctor_user/features/vaccine/presentation/vaccine_providers.dart';

import '../helpers/widget_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('home_refresh_test', () {
    testWidgets('keeps previous dashboard visible while reloading', (
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
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: _homeOverrides(context),
          child: testMaterialApp(
            home: const Scaffold(body: HomePage()),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Karim'), findsOneWidget);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomePage)),
      );
      container.read(dashboardProvider.notifier).reload(forceRefresh: true);
      await tester.pump();

      expect(find.text('Karim'), findsOneWidget);
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('shows retry instead of blank when dashboard is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardProvider.overrideWith(_NullDashboardNotifier.new),
            dashboardPollProvider.overrideWith(_StubPollNotifier.new),
          ],
          child: testMaterialApp(
            home: const Scaffold(body: HomePage()),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Try again'), findsOneWidget);
      expect(find.byType(HomePage), findsOneWidget);
    });
  });
}

List<Override> _homeOverrides(DashboardContext context) {
  return [
    dashboardProvider.overrideWith(() => _StubDashboardNotifier(context)),
    dashboardMetricsProvider.overrideWith(
      (ref) async => const DashboardMetrics(
        totalFarms: 1,
        totalAnimals: 1,
        activeAppointments: 0,
        unreadNotifications: 0,
      ),
    ),
    mobileMeProvider.overrideWith(_StubMobileMeNotifier.new),
    homeAnimalSummaryProvider.overrideWith(
      (ref) async => const HomeAnimalSummaryMetrics(
        totalAnimals: 1,
        vaccineDue: 0,
        activeTreatments: 0,
        tasks: 0,
      ),
    ),
    homeHealthTasksProvider.overrideWith((ref) async => const []),
    homeDoctorsPreviewProvider.overrideWith((ref) async => const []),
    vaccineReminderProvider.overrideWith(
      (ref) async => const VaccineRemindersData(overdue: [], upcoming: []),
    ),
    serviceCategoriesProvider.overrideWith((ref) async => const []),
    homeMarketplacePreviewProvider.overrideWith(
      (ref) async => HomeMarketplacePreview.empty,
    ),
    homeCommunityPreviewProvider.overrideWith(
      (ref) async => HomeCommunityPreview.empty,
    ),
    supportHelpProvider.overrideWith(_StubSupportHelpNotifier.new),
    animalListProvider.overrideWith(_StubAnimalListNotifier.new),
    notificationListProvider.overrideWith(_StubNotificationListNotifier.new),
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
    unreadNotificationCountProvider.overrideWith(_StubUnreadNotifier.new),
  ];
}

class _StubDashboardNotifier extends DashboardNotifier {
  _StubDashboardNotifier(this._value);

  final DashboardContext _value;

  @override
  Future<DashboardContext?> build() async => _value;
}

class _NullDashboardNotifier extends DashboardNotifier {
  @override
  Future<DashboardContext?> build() async => null;
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
