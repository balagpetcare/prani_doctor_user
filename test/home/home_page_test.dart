import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pranidoctor_user/features/home/data/dashboard_context_dto.dart';
import 'package:pranidoctor_user/features/home/home_page.dart';
import 'package:pranidoctor_user/features/home/presentation/home_providers.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomePage', () {
    testWidgets('shows summary cards when dashboard loads', (tester) async {
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
            dashboardProvider.overrideWith(() => _StubDashboardNotifier(context)),
            dashboardSummaryProvider.overrideWith(
              (ref) async => DashboardSummary(
                context: context,
                totalFarms: 1,
                totalAnimals: 3,
                activeAppointments: 2,
                unreadNotifications: 1,
              ),
            ),
            dashboardPollProvider.overrideWith(_StubPollNotifier.new),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: HomePage()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Karim'), findsOneWidget);
      expect(find.text('Summary'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows skeleton while loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardProvider.overrideWith(() => _LoadingDashboardNotifier()),
            dashboardPollProvider.overrideWith(_StubPollNotifier.new),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: HomePage()),
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
