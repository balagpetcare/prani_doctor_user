import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../milk/presentation/widgets/milk_simple_chart.dart';
import 'feed_providers.dart';
import 'widgets/feed_feedback.dart';

class FeedAnalyticsPage extends ConsumerWidget {
  const FeedAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final analyticsAsync = ref.watch(feedAnalyticsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.feedAnalyticsTitle)),
      body: analyticsAsync.when(
        loading: FeedFeedback.loading,
        error: (e, _) => FeedFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.invalidate(feedAnalyticsProvider),
        ),
        data: (analytics) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(feedAnalyticsProvider);
              await ref.read(feedAnalyticsProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (analytics.fromCache) FeedFeedback.offlineHint(context),
                Text(
                  l10n.feedCostBreakdownTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (analytics.costBreakdown.isEmpty)
                  Text(l10n.feedEmpty)
                else
                  ...analytics.costBreakdown.map(
                    (b) => ListTile(
                      dense: true,
                      title: Text(b.feedType),
                      trailing: Text(l10n.feedCostValue(b.costBdt)),
                      subtitle: Text(
                        '${b.amount.toStringAsFixed(2)} · ${b.count} records',
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  l10n.feedConsumptionTrendTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (analytics.consumptionTrend.isEmpty)
                  Text(l10n.feedEmpty)
                else
                  MilkSimpleBarChart(
                    labels: analytics.consumptionTrend
                        .map((t) => t.date.substring(5))
                        .toList(),
                    values: analytics.consumptionTrend
                        .map((t) => t.amount)
                        .toList(),
                  ),
                const SizedBox(height: 16),
                Text(
                  l10n.feedEfficiencyTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ListTile(
                  title: Text(l10n.feedCostPerKg),
                  trailing: Text(
                    l10n.feedCostValue(analytics.efficiency.costPerKg),
                  ),
                ),
                ListTile(
                  title: Text(l10n.feedCostPerAnimal),
                  trailing: Text(
                    l10n.feedCostValue(analytics.efficiency.costPerAnimal),
                  ),
                ),
                ListTile(
                  title: Text(l10n.feedAvgCostPerRecord),
                  trailing: Text(
                    l10n.feedCostValue(analytics.efficiency.avgCostPerRecord),
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
