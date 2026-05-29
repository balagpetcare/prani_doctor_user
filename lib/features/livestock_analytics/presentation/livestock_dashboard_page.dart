import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../core/localization/translation_keys.dart';
import '../../../routing/app_routes.dart';
import '../../milk/presentation/widgets/milk_simple_chart.dart';
import '../../ecosystem/presentation/active_farm_ref_provider.dart';
import 'analytics_providers.dart';
import 'widgets/analytics_feedback.dart';

class LivestockDashboardPage extends ConsumerWidget {
  const LivestockDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.tr;
    final farmRef = ref.watch(activeFarmRefProvider);
    if (farmRef == null || farmRef.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.t(TranslationKeys.analyticsDashboardTitle))),
        body: AnalyticsFeedback.noFarm(context),
      );
    }

    final dashboardAsync = ref.watch(livestockDashboardProvider);
    final profitLossAsync = ref.watch(profitLossProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t(TranslationKeys.analyticsDashboardTitle)),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights_outlined),
            onPressed: () => context.push(AppRoutes.feedEfficiency),
          ),
        ],
      ),
      body: dashboardAsync.when(
        loading: AnalyticsFeedback.loading,
        error: (e, _) => AnalyticsFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.invalidate(livestockDashboardProvider),
        ),
        data: (dashboard) {
          if (dashboard == null) {
            return AnalyticsFeedback.noFarm(context);
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(livestockDashboardProvider);
              ref.invalidate(profitLossProvider);
              await ref.read(livestockDashboardProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (dashboard.fromCache) AnalyticsFeedback.offlineHint(context),
                Text(
                  '${dashboard.period.from} — ${dashboard.period.to}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                _MetricCard(
                  title: l10n.t(TranslationKeys.analyticsActiveAnimals),
                  value: '${dashboard.activeAnimals}/${dashboard.totalAnimals}',
                  icon: Icons.pets,
                ),
                _MetricCard(
                  title: l10n.t(TranslationKeys.analyticsFeedCost),
                  value: '৳${dashboard.feedCostBdt.toStringAsFixed(0)}',
                  icon: Icons.grass_outlined,
                ),
                _MetricCard(
                  title: l10n.t(TranslationKeys.analyticsTotalExpense),
                  value: '৳${dashboard.totalExpenseBdt.toStringAsFixed(0)}',
                  icon: Icons.payments_outlined,
                ),
                _MetricCard(
                  title: l10n.t(TranslationKeys.analyticsLowStock),
                  value: '${dashboard.lowStockCount}',
                  icon: Icons.warning_amber_outlined,
                ),
                if (dashboard.bySpecies.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.t(TranslationKeys.analyticsSpeciesBreakdown),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  MilkSimpleBarChart(
                    labels: dashboard.bySpecies.keys.toList(),
                    values: dashboard.bySpecies.values
                        .map((v) => v.toDouble())
                        .toList(),
                  ),
                ],
                profitLossAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (pl) {
                    if (pl == null || pl.breakdown.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          l10n.t(TranslationKeys.analyticsMonthlyReport),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        MilkSimpleBarChart(
                          labels: pl.breakdown.map((b) => b.category).toList(),
                          values: pl.breakdown.map((b) => b.amountBdt).toList(),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class FeedEfficiencyPage extends ConsumerWidget {
  const FeedEfficiencyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.tr;
    final farmRef = ref.watch(activeFarmRefProvider);
    if (farmRef == null || farmRef.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.t(TranslationKeys.analyticsFeedEfficiency))),
        body: AnalyticsFeedback.noFarm(context),
      );
    }

    final efficiencyAsync = ref.watch(feedEfficiencyProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t(TranslationKeys.analyticsFeedEfficiency))),
      body: efficiencyAsync.when(
        loading: AnalyticsFeedback.loading,
        error: (e, _) => AnalyticsFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.invalidate(feedEfficiencyProvider),
        ),
        data: (metrics) {
          if (metrics == null) {
            return AnalyticsFeedback.noFarm(context);
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (metrics.fromCache) AnalyticsFeedback.offlineHint(context),
              _MetricCard(
                title: l10n.t(TranslationKeys.analyticsTotalFeedKg),
                value: metrics.totalFeedKg.toStringAsFixed(1),
                icon: Icons.scale,
              ),
              _MetricCard(
                title: l10n.t(TranslationKeys.analyticsFeedCost),
                value: '৳${metrics.totalFeedCostBdt.toStringAsFixed(0)}',
                icon: Icons.monetization_on_outlined,
              ),
              if (metrics.avgFeedKgPerLivestock != null)
                _MetricCard(
                  title: l10n.t(TranslationKeys.analyticsAvgFeedPerAnimal),
                  value: metrics.avgFeedKgPerLivestock!.toStringAsFixed(2),
                  icon: Icons.analytics_outlined,
                ),
              if (metrics.costPerLivestockBdt != null)
                _MetricCard(
                  title: l10n.t(TranslationKeys.analyticsCostPerAnimal),
                  value: '৳${metrics.costPerLivestockBdt!.toStringAsFixed(0)}',
                  icon: Icons.calculate_outlined,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
