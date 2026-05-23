import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../routing/app_routes.dart';
import '../theme/home_tokens.dart';
import 'home_card.dart';
import 'home_layout.dart';

class HomeInsightSection extends StatelessWidget {
  const HomeInsightSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final columns = HomeTokens.gridCrossAxisCount(context, phone: 2, tablet: 4);

    return SliverToBoxAdapter(
      child: HomeSectionScope(
        label: l10n.healthDashboardTitle,
        child: Padding(
          padding: const EdgeInsets.only(top: HomeTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeSectionHeader(title: l10n.healthDashboardTitle),
              Padding(
                padding: HomeTokens.pageHorizontal(context),
                child: GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: HomeTokens.space12,
                  crossAxisSpacing: HomeTokens.space12,
                  childAspectRatio: 1.8,
                  children: [
                    _InsightTile(
                      icon: Icons.health_and_safety_outlined,
                      label: l10n.healthDashboardTitle,
                      onTap: () => context.push(AppRoutes.health),
                    ),
                    _InsightTile(
                      icon: Icons.analytics_outlined,
                      label: l10n.healthAnalyticsTitle,
                      onTap: () => context.push(AppRoutes.healthAnalytics),
                    ),
                    _InsightTile(
                      icon: Icons.timeline_outlined,
                      label: l10n.healthTimelineTitle,
                      onTap: () => context.push(AppRoutes.healthTimeline),
                    ),
                    _InsightTile(
                      icon: Icons.history_outlined,
                      label: l10n.homeHealthHistoryAction,
                      onTap: () => context.push(AppRoutes.healthHistory),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HomeSurfaceCard(
      onTap: onTap,
      semanticLabel: label,
      padding: const EdgeInsets.all(HomeTokens.space12),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: HomeTokens.space8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
