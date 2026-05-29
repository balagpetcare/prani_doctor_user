import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../routing/app_routes.dart';
import '../../farm/presentation/farm_providers.dart';
import 'inventory_providers.dart';
import 'utils/inventory_days_remaining.dart';
import 'widgets/inventory_feedback.dart';
import 'widgets/inventory_item_card.dart';

class InventoryFeedListPage extends ConsumerWidget {
  const InventoryFeedListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.tr;
    final farmId = ref.watch(activeFarmIdProvider).valueOrNull;
    if (farmId == null || farmId.isEmpty) {
      return Scaffold(
        body: Center(child: Text(l10n.t('inventorySelectFarmFirst'))),
      );
    }

    final listAsync = ref.watch(inventoryFeedListProvider(farmId));
    final recentFeeds = ref.watch(inventoryRecentFeedLogsProvider(farmId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('inventoryFeedStock')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push(AppRoutes.inventoryFeedCreate),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.inventoryFeedCreate),
        icon: const Icon(Icons.add),
        label: Text(l10n.t('inventoryAddFeed')),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(inventoryFeedListProvider(farmId));
          await ref.read(inventoryFeedListProvider(farmId).future);
        },
        child: listAsync.when(
          loading: () => InventoryFeedback.loading(),
          error: (e, _) => InventoryFeedback.error(
            context,
            message: e.toString(),
            onRetry: () => ref.invalidate(inventoryFeedListProvider(farmId)),
          ),
          data: (state) {
            if (state.result.items.isEmpty) {
              return InventoryFeedback.empty(
                message: l10n.feedEmpty,
                actionLabel: l10n.t('inventoryAddFeed'),
                onAction: () => context.push(AppRoutes.inventoryFeedCreate),
                icon: Icons.grass_outlined,
              );
            }
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (state.result.fromCache) InventoryFeedback.offlineHint(context),
                if (state.result.lowStockAlerts.isNotEmpty)
                  _LowStockStrip(
                    count: state.result.lowStockAlerts.length,
                    label:
                        '${state.result.lowStockAlerts.length} · ${l10n.t('inventoryLowStock')}',
                  ),
                ...state.result.items.map((item) {
                  final days = estimateFeedDaysRemaining(
                    item: item,
                    recentFeeds: recentFeeds,
                  );
                  return InventoryItemCard(
                    item: item,
                    daysRemaining: days,
                    onTap: () => context.push(
                      AppRoutes.inventoryFeedDetail(item.id),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LowStockStrip extends StatelessWidget {
  const _LowStockStrip({required this.count, required this.label});

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Material(
        color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}
