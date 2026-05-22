import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import 'milk_providers.dart';
import 'widgets/milk_feedback.dart';
import 'widgets/milk_simple_chart.dart';

class MilkChartsPage extends ConsumerWidget {
  const MilkChartsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final chartsAsync = ref.watch(milkChartsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.milkChartsTitle)),
      body: chartsAsync.when(
        loading: () => MilkFeedback.loading(),
        error: (e, _) => MilkFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.invalidate(milkChartsProvider),
        ),
        data: (charts) {
          final dailyLabels = charts.dailyProduction.map((d) => d.date.substring(5)).toList();
          final dailyValues = charts.dailyProduction.map((d) => d.totalLiters).toList();
          final weeklyLabels = charts.weeklyTrend.map((w) => w.label.substring(5)).toList();
          final weeklyValues = charts.weeklyTrend.map((w) => w.totalLiters).toList();
          final monthlyLabels = charts.monthlyTrend.map((m) => m.label).toList();
          final monthlyValues = charts.monthlyTrend.map((m) => m.totalLiters).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(milkChartsProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (charts.fromCache) MilkFeedback.offlineHint(context),
                Text(l10n.milkDailyProductionTitle, style: Theme.of(context).textTheme.titleMedium),
                if (dailyValues.isEmpty)
                  Text(l10n.milkEmpty)
                else
                  MilkSimpleBarChart(labels: dailyLabels, values: dailyValues),
                const SizedBox(height: 24),
                Text(l10n.milkWeeklyTrendTitle, style: Theme.of(context).textTheme.titleMedium),
                if (weeklyValues.isEmpty)
                  Text(l10n.milkEmpty)
                else
                  MilkSimpleBarChart(
                    labels: weeklyLabels,
                    values: weeklyValues,
                    barColor: Theme.of(context).colorScheme.tertiary,
                  ),
                const SizedBox(height: 24),
                Text(l10n.milkMonthlyTrendTitle, style: Theme.of(context).textTheme.titleMedium),
                if (monthlyValues.isEmpty)
                  Text(l10n.milkEmpty)
                else
                  MilkSimpleBarChart(
                    labels: monthlyLabels,
                    values: monthlyValues,
                    barColor: Theme.of(context).colorScheme.secondary,
                  ),
                const SizedBox(height: 24),
                Text(l10n.milkSessionSplitTitle, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                MilkSessionSplitChart(
                  morningLiters: charts.morningLiters,
                  eveningLiters: charts.eveningLiters,
                  morningLabel: l10n.milkSessionMorning,
                  eveningLabel: l10n.milkSessionEvening,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
