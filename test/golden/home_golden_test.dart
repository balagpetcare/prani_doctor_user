import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:pranidoctor_user/theme/app_theme.dart';

import '../helpers/widget_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const context = DashboardContext(
    dashboardType: DashboardType.general,
    user: DashboardContextUser(
      id: '1',
      name: 'Karim',
      phone: '+8801712345678',
      email: 'k@example.com',
    ),
    farmSummary: FarmSummary(
      animalCount: 2,
      activeAnimalCount: 2,
      primaryVillageId: 'v1',
      primaryVillageLabelBn: 'Test Village',
    ),
  );

  Widget buildHarness({
    required ThemeData theme,
    Size size = const Size(390, 844),
  }) {
    return ProviderScope(
      overrides: [
        dashboardProvider.overrideWith(() => _GoldenDashboardNotifier(context)),
        dashboardMetricsProvider.overrideWith(
          (ref) async => const DashboardMetrics(
            totalFarms: 1,
            totalAnimals: 2,
            activeAppointments: 0,
            unreadNotifications: 0,
          ),
        ),
        mobileMeProvider.overrideWith(_GoldenMobileMeNotifier.new),
        homeAnimalSummaryProvider.overrideWith(
          (ref) async => const HomeAnimalSummaryMetrics(
            totalAnimals: 2,
            vaccineDue: 0,
            activeTreatments: 0,
            tasks: 0,
          ),
        ),
        homeHealthTasksProvider.overrideWith((ref) async => const []),
        homeDoctorsPreviewProvider.overrideWith((ref) async => const []),
        homeMarketplacePreviewProvider.overrideWith(
          (ref) async => HomeMarketplacePreview.empty,
        ),
        homeCommunityPreviewProvider.overrideWith(
          (ref) async => HomeCommunityPreview.empty,
        ),
        supportHelpProvider.overrideWith(_GoldenSupportHelpNotifier.new),
        vaccineReminderProvider.overrideWith(
          (ref) async => const VaccineRemindersData(overdue: [], upcoming: []),
        ),
        serviceCategoriesProvider.overrideWith((ref) async => const []),
        dashboardPollProvider.overrideWith(_GoldenPollNotifier.new),
        unreadNotificationCountProvider.overrideWith(_GoldenUnreadNotifier.new),
      ],
      child: testMaterialApp(
        theme: theme,
        viewportSize: size,
        home: const Scaffold(body: HomePage()),
      ),
    );
  }

  group('home golden', () {
    testWidgets('home light', (tester) async {
      await tester.pumpWidget(buildHarness(theme: AppTheme.light()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await expectLater(
        find.byType(HomePage),
        matchesGoldenFile('goldens/home_light.png'),
      );
    });

    testWidgets('home dark', (tester) async {
      await tester.pumpWidget(buildHarness(theme: AppTheme.dark()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await expectLater(
        find.byType(HomePage),
        matchesGoldenFile('goldens/home_dark.png'),
      );
    });

    testWidgets('home tablet', (tester) async {
      await tester.pumpWidget(
        buildHarness(theme: AppTheme.light(), size: const Size(900, 1200)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await expectLater(
        find.byType(HomePage),
        matchesGoldenFile('goldens/home_tablet.png'),
      );
    });
  });
}

class _GoldenDashboardNotifier extends DashboardNotifier {
  _GoldenDashboardNotifier(this._value);

  final DashboardContext _value;

  @override
  Future<DashboardContext?> build() async => _value;
}

class _GoldenMobileMeNotifier extends MobileMeNotifier {
  @override
  Future<MobileMeDto?> build() async => null;
}

class _GoldenSupportHelpNotifier extends SupportHelpNotifier {
  @override
  Future<SupportHelpData> build() async => const SupportHelpData();
}

class _GoldenPollNotifier extends DashboardPollNotifier {
  @override
  int build() => 0;
}

class _GoldenUnreadNotifier extends UnreadNotificationCountNotifier {
  @override
  Future<int> build() async => 0;
}
