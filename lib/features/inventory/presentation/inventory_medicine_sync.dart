import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../treatment/data/treatment_dto.dart';
import '../data/inventory_dto.dart';
import '../data/inventory_repository.dart';
import 'inventory_navigation.dart';
import 'inventory_providers.dart';

/// After a treatment is saved, optionally deduct matching medicine stock.
Future<void> syncMedicineStockFromTreatment({
  required WidgetRef ref,
  required String farmRef,
  required String treatmentId,
  required List<MedicineItem> medicines,
}) async {
  if (medicines.isEmpty) return;

  final listState = await ref.read(inventoryMedicineListProvider(farmRef).future);
  final catalog = listState.result.items;
  final repo = ref.read(inventoryRepositoryProvider);

  for (final med in medicines) {
    final name = med.name.trim().toLowerCase();
    if (name.isEmpty) continue;

    InventoryItem? match;
    for (final item in catalog) {
      if (item.displayName.trim().toLowerCase() == name) {
        match = item;
        break;
      }
    }
    if (match == null) continue;

    final qty = med.durationDays != null && med.durationDays! > 0
        ? med.durationDays!.toDouble()
        : 1.0;

    await repo.consumeStock(
      InventoryConsumeInput(
        farmRef: farmRef,
        inventoryType: InventoryType.medicine,
        inventoryItemId: match.id,
        quantity: qty,
        sourceType: 'FARM_TREATMENT',
        sourceId: treatmentId,
        reason: 'Treatment: ${med.name}',
        useReserved: true,
      ),
    );
  }

  InventoryNavigation.afterStockChange(ref, farmRef);
}
