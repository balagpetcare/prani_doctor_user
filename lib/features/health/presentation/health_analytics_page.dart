import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/navigation/navigation_guard.dart';

import '../../milk/presentation/widgets/milk_simple_chart.dart';
import 'health_providers.dart';
import 'widgets/health_feedback.dart';
import 'widgets/health_labels.dart';

class HealthAnalyticsPage extends ConsumerWidget {
  const HealthAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final analyticsAsync = ref.watch(healthAnalyticsProvider);

    return Scaffold(
      appBar: safeAppBar(context, title: Text(l10n.healthAnalyticsTitle)),
      body: analyticsAsync.when(
        loading: HealthFeedback.loading,
        error: (e, _) => HealthFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.invalidate(healthAnalyticsProvider),
        ),
        data: (analytics) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(healthAnalyticsProvider);
              await ref.read(healthAnalyticsProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (analytics.fromCache) HealthFeedback.offlineHint(context),
                Text(
                  l10n.healthAnalyticsTypeBreakdown,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (analytics.eventTypeBreakdown.isEmpty)
                  Text(l10n.healthEmpty)
                else
                  ...analytics.eventTypeBreakdown.map(
                    (b) => ListTile(
                      dense: true,
                      title: Text(healthEventTypeLabel(l10n, b.eventType)),
                      trailing: Text('${b.count}'),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  l10n.healthAnalyticsDiseaseFrequency,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (analytics.diseaseFrequency.isEmpty)
                  Text(l10n.healthAnalyticsNoDiseases)
                else
                  ...analytics.diseaseFrequency.map(
                    (d) => ListTile(
                      dense: true,
                      title: Text(d.name),
                      trailing: Text('${d.count}'),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  l10n.healthAnalyticsMonthlyTrend,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (analytics.monthlyTrend.isEmpty)
                  Text(l10n.healthEmpty)
                else
                  MilkSimpleBarChart(
                    labels: analytics.monthlyTrend
                        .map((t) => t.month.substring(5))
                        .toList(),
                    values: analytics.monthlyTrend
                        .map((t) => t.count.toDouble())
                        .toList(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
