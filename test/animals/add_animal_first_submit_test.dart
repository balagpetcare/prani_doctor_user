import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/core/error/api_result.dart';
import 'package:pranidoctor_user/features/animals/data/animal_dto.dart';
import 'package:pranidoctor_user/features/animals/data/animal_repository.dart';
import 'package:pranidoctor_user/features/animals/data/animal_repository_contract.dart';
import 'package:pranidoctor_user/features/animals/presentation/animal_form_page.dart';
import 'package:pranidoctor_user/features/animals/presentation/animal_providers.dart';
import 'package:pranidoctor_user/features/home/data/dashboard_context_dto.dart';
import 'package:pranidoctor_user/features/farm/data/farm_dto.dart';
import 'package:pranidoctor_user/features/farm/presentation/farm_providers.dart';
import 'package:pranidoctor_user/features/home/presentation/home_providers.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../helpers/widget_test_harness.dart';

class _FakeAnimalRepository implements AnimalRepositoryContract {
  int createCalls = 0;

  @override
  Future<ApiResult<AnimalProfile>> createAnimal(AnimalInput input) async {
    createCalls++;
    return ApiResult.success(
      AnimalProfile(
        id: 'new-animal',
        customerId: 'c1',
        name: input.name ?? input.tag ?? 'Animal',
        species: input.animalType,
        category: 'LIVESTOCK',
        animalType: input.animalType,
        active: true,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
    );
  }

  @override
  Future<void> clearDraft({String? animalId}) async {}

  @override
  Future<ApiResult<AnimalProfile>> deactivateAnimal(String id) =>
      throw UnimplementedError();

  @override
  Future<ApiResult<AnimalDetail>> getAnimal(String id, {bool forceRefresh = false}) =>
      throw UnimplementedError();

  @override
  Future<ApiResult<AnimalPageResult>> listAnimals({
    int page = 1,
    int pageSize = 20,
    String search = '',
    AnimalFilter filter = AnimalFilter.all,
    AnimalSort sort = AnimalSort.recentFirst,
    bool includeInactive = false,
    bool forceRefresh = false,
  }) =>
      throw UnimplementedError();

  @override
  Future<AnimalPageResult?> readCachedList() async => null;

  @override
  Future<AnimalInput?> readDraft({String? animalId}) async => null;

  @override
  Future<void> saveDraft(AnimalInput input, {String? animalId}) async {}

  @override
  Future<ApiResult<AnimalProfile>> updateAnimal(String id, AnimalInput input) =>
      throw UnimplementedError();

  @override
  Future<ApiResult<String>> uploadPhoto(
    String filePath, {
    void Function(int sent, int total)? onProgress,
  }) =>
      throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpForm(WidgetTester tester, _FakeAnimalRepository repo) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const AnimalFormPage(),
        ),
        GoRoute(
          path: '/animals/:id',
          builder: (_, state) => Scaffold(
            body: Text('detail-${state.pathParameters['id']}'),
          ),
        ),
      ],
    );

    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          animalRepositoryProvider.overrideWithValue(repo),
          animalListProvider.overrideWith(_StubAnimalListNotifier.new),
          farmListProvider.overrideWith(_StubFarmListNotifier.new),
          dashboardProvider.overrideWith(_StubDashboardNotifier.new),
        ],
        child: MaterialApp.router(
          locale: testLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
  }

  group('add_animal_first_submit_test', () {
    testWidgets('first submit on final step creates animal immediately', (
      tester,
    ) async {
      final repo = _FakeAnimalRepository();

      await pumpForm(tester, repo);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Bella');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Add animal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(repo.createCalls, 1);
      expect(find.text('detail-new-animal'), findsOneWidget);
    });

    testWidgets('validation error on final step is visible and retryable', (
      tester,
    ) async {
      final repo = _FakeAnimalRepository();

      await pumpForm(tester, repo);
      await tester.pumpAndSettle();

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.widgetWithText(FilledButton, 'Add animal'));
      await tester.pumpAndSettle();

      expect(repo.createCalls, 0);
      expect(find.widgetWithText(FilledButton, 'Next'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Enter a name or tag'), findsWidgets);
    });
  });
}

class _StubAnimalListNotifier extends AnimalListNotifier {
  @override
  Future<AnimalListState> build() async =>
      const AnimalListState(animals: [], total: 0);
}

class _StubDashboardNotifier extends DashboardNotifier {
  @override
  Future<DashboardContext?> build() async => null;
}

class _StubFarmListNotifier extends FarmListNotifier {
  @override
  Future<FarmListState> build() async => const FarmListState(farms: [], total: 0);
}
