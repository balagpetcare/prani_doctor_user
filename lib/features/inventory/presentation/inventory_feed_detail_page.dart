import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../core/localization/translation_keys.dart';
import '../../../routing/app_routes.dart';
import '../../farm/presentation/farm_providers.dart';
import '../data/inventory_dto.dart';
import 'inventory_providers.dart';
import 'utils/inventory_days_remaining.dart';
import 'widgets/stock_quantity_chip.dart';

class InventoryFeedDetailPage extends ConsumerWidget {
  const InventoryFeedDetailPage({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.tr;
    final farmId = ref.watch(activeFarmIdProvider).valueOrNull ?? '';
    final listAsync = ref.watch(inventoryFeedListProvider(farmId));
    final recentFeeds = ref.watch(inventoryRecentFeedLogsProvider(farmId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('inventoryFeedItem'))),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (state) {
          final item = state.result.items
              .where((i) => i.id == itemId)
              .cast<InventoryItem?>()
              .firstWhere((i) => i != null, orElse: () => null);
          if (item == null) {
            return Center(child: Text(l10n.t('inventoryItemNotFound')));
          }
          final days = estimateFeedDaysRemaining(
            item: item,
            recentFeeds: recentFeeds,
          );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(item.displayName, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              StockQuantityChip(
                quantity: item.quantityAvailable,
                unit: item.unitLabel,
                isLowStock: item.isLowStock,
              ),
              if (days != null) ...[
                const SizedBox(height: 8),
                Text(l10n.translate(TranslationKeys.inventoryDaysRemaining, {'days': days})),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.push(
                  AppRoutes.inventoryFeedReceipt(itemId),
                ),
                icon: const Icon(Icons.add),
                label: Text(l10n.t('inventoryAddStock')),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => context.push(
                  '${AppRoutes.feedCreate}?inventoryItemId=$itemId&deductStock=1',
                ),
                icon: const Icon(Icons.restaurant),
                label: Text(l10n.t('inventoryLogFeeding')),
              ),
            ],
          );
        },
      ),
    );
  }
}

class InventoryMedicineDetailPage extends ConsumerWidget {
  const InventoryMedicineDetailPage({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.tr;
    final farmId = ref.watch(activeFarmIdProvider).valueOrNull ?? '';
    final listAsync = ref.watch(inventoryMedicineListProvider(farmId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('inventoryMedicineItem'))),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (state) {
          final item = state.result.items
              .where((i) => i.id == itemId)
              .cast<InventoryItem?>()
              .firstWhere((i) => i != null, orElse: () => null);
          if (item == null) {
            return Center(child: Text(l10n.t('inventoryItemNotFound')));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(item.displayName, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(l10n.t(TranslationKeys.inventoryMedicineStockNote)),
              const SizedBox(height: 12),
              StockQuantityChip(
                quantity: item.quantityAvailable,
                unit: item.unitLabel,
                isLowStock: item.isLowStock,
              ),
              if (item.quantityReserved > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '${l10n.t('inventoryReserved')}: ${item.quantityReserved} ${item.unitLabel}',
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.push(
                  AppRoutes.inventoryMedicineReceipt(itemId),
                ),
                icon: const Icon(Icons.add),
                label: Text(l10n.t('inventoryAddStock')),
              ),
            ],
          );
        },
      ),
    );
  }
}
