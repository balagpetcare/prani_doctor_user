import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/features/profile/data/mobile_me_dto.dart';
import 'package:pranidoctor_user/features/profile/presentation/profile_completion_page.dart';
import 'package:pranidoctor_user/features/profile/presentation/profile_providers.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';
import 'package:pranidoctor_user/routing/app_routes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const incompleteProfile = MobileMeDto(
    id: '1',
    name: 'Karim',
    phone: '+8801',
    email: '',
    locale: 'bn-BD',
    role: 'customer',
    profileComplete: false,
  );

  const completeProfile = MobileMeDto(
    id: '1',
    name: 'Karim',
    phone: '+8801',
    email: '',
    locale: 'bn-BD',
    role: 'customer',
    profileComplete: false,
    address: MobileMeAddressDto(unionId: 'union-1'),
  );

  Widget _wrap(Widget child, {List<Override> overrides = const []}) {
    final router = GoRouter(
      initialLocation: AppRoutes.settingsProfileComplete,
      routes: [
        GoRoute(
          path: AppRoutes.settingsProfileComplete,
          builder: (context, state) => child,
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) =>
              const Scaffold(body: Text('Home reached')),
        ),
      ],
    );
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  group('ProfileCompletionPage', () {
    testWidgets('disables continue when union is missing', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ProfileCompletionPage(),
          overrides: [
            mobileMeProvider.overrideWith(
              () => _StubMobileMeNotifier(incompleteProfile),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('enables continue when name and union are present', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const ProfileCompletionPage(),
          overrides: [
            mobileMeProvider.overrideWith(
              () => _StubMobileMeNotifier(completeProfile),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('continue navigates to home after refresh', (tester) async {
      final notifier = _StubMobileMeNotifier(completeProfile);

      await tester.pumpWidget(
        _wrap(
          const ProfileCompletionPage(),
          overrides: [mobileMeProvider.overrideWith(() => notifier)],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('Home reached'), findsOneWidget);
      expect(notifier.reloadCount, greaterThan(0));
    });
  });
}

class _StubMobileMeNotifier extends MobileMeNotifier {
  _StubMobileMeNotifier(this._profile);

  final MobileMeDto _profile;
  int reloadCount = 0;

  @override
  Future<MobileMeDto?> build() async => _profile;

  @override
  Future<void> reload({bool forceRefresh = false}) async {
    reloadCount++;
    state = AsyncData(_profile);
  }
}
