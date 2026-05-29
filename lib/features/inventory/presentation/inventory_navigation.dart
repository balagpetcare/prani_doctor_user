import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'inventory_providers.dart';

abstract final class InventoryNavigation {
  static void invalidateAll(WidgetRef ref, {String? farmRef}) {
    if (farmRef != null) {
      ref.invalidate(inventoryDashboardProvider(farmRef));
      ref.invalidate(inventoryFeedListProvider(farmRef));
      ref.invalidate(inventoryMedicineListProvider(farmRef));
    }
  }

  static void afterStockChange(WidgetRef ref, String farmRef) {
    invalidateAll(ref, farmRef: farmRef);
  }
}
