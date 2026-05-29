import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../core/localization/translation_keys.dart';
import '../../../routing/app_routes.dart';

/// Phase 4 hub linking livestock, feed, inventory, recommendations, analytics.
class EcosystemHubPage extends ConsumerWidget {
  const EcosystemHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.tr;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t(TranslationKeys.ecosystemHubTitle))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.t(TranslationKeys.ecosystemHubSubtitle),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _Tile(
            icon: Icons.pets,
            title: l10n.t(TranslationKeys.livestockListTitle),
            route: AppRoutes.livestock,
          ),
          _Tile(
            icon: Icons.grass,
            title: l10n.t(TranslationKeys.phase4FeedHubTitle),
            route: AppRoutes.phase4FeedHub,
          ),
          _Tile(
            icon: Icons.inventory_2_outlined,
            title: l10n.t(TranslationKeys.inventoryTitle),
            route: AppRoutes.inventory,
          ),
          _Tile(
            icon: Icons.psychology_outlined,
            title: l10n.t(TranslationKeys.aiHomeTitle),
            route: AppRoutes.ai,
          ),
          _Tile(
            icon: Icons.medical_information_outlined,
            title: 'লক্ষণ যাচাই',
            route: AppRoutes.aiSymptomChecker,
          ),
          _Tile(
            icon: Icons.health_and_safety_outlined,
            title: 'খামার স্বাস্থ্য',
            route: AppRoutes.aiFarmHealth,
          ),
          _Tile(
            icon: Icons.insights,
            title: l10n.t(TranslationKeys.analyticsDashboardTitle),
            route: AppRoutes.livestockAnalytics,
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(route),
      ),
    );
  }
}
