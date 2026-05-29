import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../core/localization/translation_keys.dart';
import '../../../routing/app_routes.dart';
import '../../../shared/theme/app_colors.dart';
import '../../farm/presentation/farm_providers.dart';
import 'inventory_providers.dart';
import 'widgets/inventory_dashboard_cards.dart';
import 'widgets/inventory_feedback.dart';

/// Inventory hub / dashboard for the active farm.
class InventoryHomePage extends ConsumerWidget {
  const InventoryHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.tr;
    final farmId = ref.watch(activeFarmIdProvider).valueOrNull;

    if (farmId == null || farmId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.t(TranslationKeys.inventoryTitle))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.t(TranslationKeys.inventoryNoFarmHint),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.push(AppRoutes.farms),
                  child: Text(l10n.t(TranslationKeys.inventoryGoToFarms)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final summaryAsync = ref.watch(inventoryDashboardProvider(farmId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t(TranslationKeys.inventoryTitle))),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(inventoryDashboardProvider(farmId));
          await ref.read(inventoryDashboardProvider(farmId).future);
        },
        child: summaryAsync.when(
          loading: () => InventoryFeedback.loading(),
          error: (e, _) => InventoryFeedback.error(
            context,
            message: e.toString(),
            onRetry: () => ref.invalidate(inventoryDashboardProvider(farmId)),
          ),
          data: (summary) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                if (summary.fromCache) InventoryFeedback.offlineHint(context),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    l10n.t(TranslationKeys.inventoryFarmOverview),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                InventoryDashboardCards(
                  summary: summary,
                  onCurrentStock: () {},
                  onLowStock: () {
                    if (summary.feedLowStockCount > 0) {
                      context.push(AppRoutes.inventoryFeed);
                    } else if (summary.medicineLowStockCount > 0) {
                      context.push(AppRoutes.inventoryMedicine);
                    }
                  },
                  onConsumptionHistory: () =>
                      context.push(AppRoutes.inventoryConsumptionHistory),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    l10n.t(TranslationKeys.inventorySections),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _SectionTile(
                  icon: Icons.grass_outlined,
                  color: AppStatusColors.forTone(
                    StatusTone.positive,
                    Theme.of(context).brightness,
                  ),
                  title: l10n.t(TranslationKeys.inventoryFeedStock),
                  subtitle:
                      '${summary.feedActiveItems} · ${summary.feedLowStockCount} ${l10n.t(TranslationKeys.inventoryLowStock)}',
                  onTap: () => context.push(AppRoutes.inventoryFeed),
                ),
                _SectionTile(
                  icon: Icons.medication_outlined,
                  color: AppStatusColors.forTone(
                    StatusTone.info,
                    Theme.of(context).brightness,
                  ),
                  title: l10n.t(TranslationKeys.inventoryMedicineStock),
                  subtitle:
                      '${summary.medicineActiveItems} · ${summary.medicineLowStockCount} ${l10n.t(TranslationKeys.inventoryLowStock)}',
                  onTap: () => context.push(AppRoutes.inventoryMedicine),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    l10n.t(TranslationKeys.inventoryDailyFeedHint),
                    style: Theme.of(context).textTheme.bodySmall,
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

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
