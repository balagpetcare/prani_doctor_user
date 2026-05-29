import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../routing/app_routes.dart';
import '../../farm/presentation/farm_providers.dart';
import 'inventory_providers.dart';
import 'widgets/inventory_feedback.dart';
import 'widgets/inventory_item_card.dart';

class InventoryMedicineListPage extends ConsumerWidget {
  const InventoryMedicineListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.tr;
    final farmId = ref.watch(activeFarmIdProvider).valueOrNull;
    if (farmId == null || farmId.isEmpty) {
      return Scaffold(
        body: Center(child: Text(l10n.t('inventorySelectFarmFirst'))),
      );
    }

    final listAsync = ref.watch(inventoryMedicineListProvider(farmId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('inventoryMedicineStock')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push(AppRoutes.inventoryMedicineCreate),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.inventoryMedicineCreate),
        icon: const Icon(Icons.add),
        label: Text(l10n.t('inventoryAddMedicine')),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(inventoryMedicineListProvider(farmId));
          await ref.read(inventoryMedicineListProvider(farmId).future);
        },
        child: listAsync.when(
          loading: () => InventoryFeedback.loading(),
          error: (e, _) => InventoryFeedback.error(
            context,
            message: e.toString(),
            onRetry: () =>
                ref.invalidate(inventoryMedicineListProvider(farmId)),
          ),
          data: (state) {
            if (state.result.items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  InventoryFeedback.empty(
                    message: l10n.t(
                      'Store medicine quantities you have on hand. Treatment plans come from your vet — not from this screen.',
                    ),
                    actionLabel: l10n.t('inventoryAddMedicine'),
                    onAction: () =>
                        context.push(AppRoutes.inventoryMedicineCreate),
                    icon: Icons.medication_outlined,
                  ),
                ],
              );
            }
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (state.result.fromCache) InventoryFeedback.offlineHint(context),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.t(
                      'Quantities only — no prescriptions or treatment decisions here.',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                if (state.result.lowStockAlerts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '${state.result.lowStockAlerts.length} · ${l10n.t('inventoryLowStock')}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ...state.result.items.map(
                  (item) => InventoryItemCard(
                    item: item,
                    onTap: () => context.push(
                      AppRoutes.inventoryMedicineDetail(item.id),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
