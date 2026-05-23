import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'farm_providers.dart';

abstract final class FarmNavigation {
  FarmNavigation._();

  static Future<void> refreshFarmList(WidgetRef ref) async {
    await ref.read(farmListProvider.notifier).refresh();
  }

  static void refreshFarmDetail(WidgetRef ref, String farmId) {
    ref.invalidate(farmDetailProvider(farmId));
  }

  static Future<void> setActiveFarm(WidgetRef ref, String farmId) async {
    await ref.read(activeFarmIdProvider.notifier).setActive(farmId);
  }
}
