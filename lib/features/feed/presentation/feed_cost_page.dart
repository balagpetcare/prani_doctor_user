import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../milk/presentation/widgets/milk_simple_chart.dart';
import 'feed_providers.dart';
import 'widgets/feed_feedback.dart';

class FeedCostPage extends ConsumerWidget {
  const FeedCostPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final costAsync = ref.watch(feedCostProvider);
    final analyticsAsync = ref.watch(feedAnalyticsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.feedCostTitle)),
      body: costAsync.when(
        loading: () => FeedFeedback.loading(),
        error: (e, _) => FeedFeedback.error(
          context,
          message: e.toString(),
          onRetry: () {
            ref.invalidate(feedCostProvider);
            ref.invalidate(feedAnalyticsProvider);
          },
        ),
        data: (cost) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(feedCostProvider);
              ref.invalidate(feedAnalyticsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (cost.fromCache) FeedFeedback.offlineHint(context),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l10n.feedTotalCost, style: Theme.of(context).textTheme.titleMedium),
                        Text(
                          l10n.feedCostValue(cost.totalCostBdt),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text('${l10n.feedTotalAmount}: ${cost.totalAmount.toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(l10n.feedDailyCostTitle, style: Theme.of(context).textTheme.titleMedium),
                if (cost.daily.isEmpty)
                  Text(l10n.feedEmpty)
                else
                  MilkSimpleBarChart(
                    labels: cost.daily.map((d) => d.label.substring(5)).toList(),
                    values: cost.daily.map((d) => d.costBdt).toList(),
                  ),
                const SizedBox(height: 16),
                Text(l10n.feedWeeklyCostTitle, style: Theme.of(context).textTheme.titleMedium),
                if (cost.weekly.isEmpty)
                  Text(l10n.feedEmpty)
                else
                  MilkSimpleBarChart(
                    labels: cost.weekly.map((w) => w.label.substring(5)).toList(),
                    values: cost.weekly.map((w) => w.costBdt).toList(),
                    barColor: Theme.of(context).colorScheme.tertiary,
                  ),
                const SizedBox(height: 16),
                Text(l10n.feedMonthlyCostTitle, style: Theme.of(context).textTheme.titleMedium),
                if (cost.monthly.isEmpty)
                  Text(l10n.feedEmpty)
                else
                  MilkSimpleBarChart(
                    labels: cost.monthly.map((m) => m.label).toList(),
                    values: cost.monthly.map((m) => m.costBdt).toList(),
                    barColor: Theme.of(context).colorScheme.secondary,
                  ),
                const SizedBox(height: 16),
                Text(l10n.feedPerAnimalTitle, style: Theme.of(context).textTheme.titleMedium),
                if (cost.byAnimal.isEmpty)
                  Text(l10n.feedEmpty)
                else
                  ...cost.byAnimal.map(
                    (a) => ListTile(
                      leading: const Icon(Icons.pets),
                      title: Text(a.animalName),
                      subtitle: Text('${l10n.feedCostValue(a.costBdt)} · ${a.amount.toStringAsFixed(2)}'),
                    ),
                  ),
                const SizedBox(height: 24),
                analyticsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => Text(l10n.feedAnalyticsError),
                  data: (analytics) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l10n.feedAnalyticsTitle, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(l10n.feedCostBreakdownTitle, style: Theme.of(context).textTheme.titleMedium),
                      if (analytics.costBreakdown.isEmpty)
                        Text(l10n.feedEmpty)
                      else
                        ...analytics.costBreakdown.map(
                          (b) => ListTile(
                            dense: true,
                            title: Text(b.feedType),
                            trailing: Text(l10n.feedCostValue(b.costBdt)),
                            subtitle: Text('${b.amount.toStringAsFixed(2)} · ${b.count} records'),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(l10n.feedConsumptionTrendTitle, style: Theme.of(context).textTheme.titleMedium),
                      if (analytics.consumptionTrend.isEmpty)
                        Text(l10n.feedEmpty)
                      else
                        MilkSimpleBarChart(
                          labels: analytics.consumptionTrend.map((t) => t.date.substring(5)).toList(),
                          values: analytics.consumptionTrend.map((t) => t.amount).toList(),
                        ),
                      const SizedBox(height: 12),
                      Text(l10n.feedEfficiencyTitle, style: Theme.of(context).textTheme.titleMedium),
                      ListTile(
                        title: Text(l10n.feedCostPerKg),
                        trailing: Text(l10n.feedCostValue(analytics.efficiency.costPerKg)),
                      ),
                      ListTile(
                        title: Text(l10n.feedCostPerAnimal),
                        trailing: Text(l10n.feedCostValue(analytics.efficiency.costPerAnimal)),
                      ),
                      ListTile(
                        title: Text(l10n.feedAvgCostPerRecord),
                        trailing: Text(l10n.feedCostValue(analytics.efficiency.avgCostPerRecord)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
