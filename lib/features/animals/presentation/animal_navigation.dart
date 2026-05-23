import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../farm/presentation/farm_providers.dart';
import '../../home/presentation/home_providers.dart';
import '../data/animal_dto.dart';
import '../data/animal_repository.dart';
import 'animal_providers.dart';

abstract final class AnimalNavigation {
  AnimalNavigation._();

  static Future<void> refreshList(WidgetRef ref) async {
    await ref.read(animalListProvider.notifier).reload(forceRefresh: true);
  }

  static void refreshDetail(WidgetRef ref, String animalId) {
    if (animalId.isEmpty) return;
    ref.invalidate(animalDetailProvider(animalId));
  }

  /// After create/edit — scoped refresh only (never profile/auth).
  static Future<void> afterSave(WidgetRef ref, AnimalProfile animal) async {
    refreshDetail(ref, animal.id);
    ref.invalidate(animalsProvider);
    ref.read(animalListProvider.notifier).upsertLocal(animal);
    try {
      await ref.read(animalListProvider.notifier).reload(forceRefresh: true);
    } catch (_) {}
    try {
      await ref.read(farmListProvider.notifier).refresh(silent: true);
    } catch (_) {}
    try {
      await ref.read(dashboardProvider.notifier).refresh(
            silent: true,
            invalidateSections: true,
          );
    } catch (_) {}
  }
}
