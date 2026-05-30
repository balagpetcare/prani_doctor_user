import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../core/localization/translation_keys.dart';
import '../../../routing/app_routes.dart';
import '../../ecosystem/presentation/active_farm_ref_provider.dart';
import 'phase4_feed_providers.dart';

class Phase4FeedHubPage extends ConsumerWidget {
  const Phase4FeedHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.tr;
    final farmRef = ref.watch(activeFarmRefProvider);
    final alertsAsync = ref.watch(phase4LowStockAlertsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t(TranslationKeys.phase4FeedHubTitle))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (farmRef == null)
            Text(l10n.t(TranslationKeys.farmEmpty))
          else
            alertsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
              data: (alerts) {
                if (alerts.isEmpty) return const SizedBox.shrink();
                return Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber_outlined),
                    title: Text(l10n.t(TranslationKeys.phase4FeedLowStockAlerts)),
                    subtitle: Text('${alerts.length}'),
                    onTap: () => context.push(AppRoutes.phase4FeedInventory),
                  ),
                );
              },
            ),
          const SizedBox(height: 8),
          _HubTile(
            icon: Icons.menu_book_outlined,
            title: l10n.t(TranslationKeys.phase4FeedCatalogTitle),
            subtitle: l10n.t(TranslationKeys.phase4FeedCatalogSubtitle),
            onTap: () => context.push(AppRoutes.phase4FeedItems),
          ),
          _HubTile(
            icon: Icons.inventory_2_outlined,
            title: l10n.t(TranslationKeys.phase4FeedInventoryTitle),
            subtitle: l10n.t(TranslationKeys.phase4FeedInventorySubtitle),
            onTap: () => context.push(AppRoutes.phase4FeedInventory),
          ),
          _HubTile(
            icon: Icons.shopping_cart_outlined,
            title: l10n.t(TranslationKeys.phase4FeedPurchaseTitle),
            subtitle: l10n.t(TranslationKeys.phase4FeedPurchaseSubtitle),
            onTap: () => context.push(AppRoutes.phase4FeedPurchase),
          ),
          _HubTile(
            icon: Icons.restaurant_outlined,
            title: l10n.t(TranslationKeys.phase4FeedConsumptionTitle),
            subtitle: l10n.t(TranslationKeys.phase4FeedConsumptionSubtitle),
            onTap: () => context.push(AppRoutes.phase4FeedConsumption),
          ),
        ],
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
