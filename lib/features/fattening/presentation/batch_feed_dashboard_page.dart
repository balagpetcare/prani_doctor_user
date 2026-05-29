import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import '../../feed/data/feed_dto.dart';
import '../../milk/presentation/widgets/milk_simple_chart.dart';
import '../data/fattening_feed_dto.dart';
import '../data/fattening_repository.dart';
import 'fattening_providers.dart';
import 'widgets/fattening_feedback.dart';

class FatteningBatchFeedDashboardPage extends ConsumerWidget {
  const FatteningBatchFeedDashboardPage({
    super.key,
    required this.farmId,
    required this.batchId,
  });

  final String farmId;
  final String batchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final dashboardAsync = ref.watch(fatteningFeedDashboardProvider(batchId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.fatteningFeedDashboardTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.fatteningEditFeedPlan,
            onPressed: () => _showPlanDialog(context, ref, dashboardAsync.valueOrNull),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
          AppRoutes.fatteningLogFeed(farmId, batchId),
        ),
        icon: const Icon(Icons.restaurant_outlined),
        label: Text(l10n.fatteningLogFeed),
      ),
      body: dashboardAsync.when(
        loading: FatteningFeedback.loading,
        error: (e, _) => FatteningFeedback.error(
          context,
          error: e,
          onRetry: () => ref.invalidate(fatteningFeedDashboardProvider(batchId)),
        ),
        data: (dashboard) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(fatteningFeedDashboardProvider(batchId));
              await ref.read(fatteningFeedDashboardProvider(batchId).future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (dashboard.fromCache) FatteningFeedback.offlineHint(context),
                if (dashboard.plan != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      label: Text(
                        dashboard.plan!.mode == BatchFeedPlanMode.fattening
                            ? l10n.fatteningPlanModeFattening
                            : l10n.fatteningPlanModeNormal,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  l10n.fatteningFeedCostSection,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: l10n.fatteningTotalFeedCost,
                        value: '৳${dashboard.feedCost.totalCostBdt.toStringAsFixed(0)}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricCard(
                        label: l10n.fatteningTodayFeedCost,
                        value: '৳${dashboard.feedCost.todayCostBdt.toStringAsFixed(0)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.fatteningDailyFeedSection,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: l10n.fatteningTodayFeedAmount,
                        value:
                            '${dashboard.dailyFeed.todayAmountKg.toStringAsFixed(1)} kg',
                        subtitle: dashboard.dailyFeed.plannedAmountKg != null
                            ? l10n.fatteningPlannedAmount(
                                dashboard.dailyFeed.plannedAmountKg!,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricCard(
                        label: l10n.fatteningAvgDailyFeed,
                        value:
                            '${dashboard.feedCost.avgDailyAmount.toStringAsFixed(1)} kg',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.fatteningDailyCostChart,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (dashboard.daily.isEmpty)
                  Text(l10n.fatteningNoFeedData)
                else
                  MilkSimpleBarChart(
                    labels: dashboard.daily
                        .map((d) => d.date.length >= 5 ? d.date.substring(5) : d.date)
                        .toList(),
                    values: dashboard.daily.map((d) => d.costBdt).toList(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showPlanDialog(
    BuildContext context,
    WidgetRef ref,
    BatchFeedDashboard? dashboard,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final plan = dashboard?.plan;
    final amountController = TextEditingController(
      text: plan?.dailyAmountKg?.toString() ?? '',
    );
    final costController = TextEditingController(
      text: plan?.dailyCostBdt?.toString() ?? '',
    );
    var mode = plan?.mode ?? BatchFeedPlanMode.fattening;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.fatteningEditFeedPlan),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<BatchFeedPlanMode>(
                segments: [
                  ButtonSegment(
                    value: BatchFeedPlanMode.normal,
                    label: Text(l10n.fatteningPlanModeNormal),
                  ),
                  ButtonSegment(
                    value: BatchFeedPlanMode.fattening,
                    label: Text(l10n.fatteningPlanModeFattening),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (s) => mode = s.first,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: l10n.fatteningPlanDailyAmount,
                  suffixText: 'kg',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: costController,
                decoration: InputDecoration(
                  labelText: l10n.fatteningPlanDailyCost,
                  prefixText: '৳ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.fatteningSavePlan),
          ),
        ],
      ),
    );

    if (saved != true || !context.mounted) return;

    final amount = double.tryParse(amountController.text.trim());
    final cost = double.tryParse(costController.text.trim());
    final result = await ref.read(fatteningRepositoryProvider).upsertFeedPlan(
      batchId,
      BatchFeedPlan(
        id: plan?.id ?? '',
        batchId: batchId,
        mode: mode,
        dailyAmountKg: amount,
        dailyCostBdt: cost,
        feedType: plan?.feedType,
        unit: plan?.unit ?? FeedUnit.kg,
        notes: plan?.notes,
        createdAt: plan?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    amountController.dispose();
    costController.dispose();

    if (!context.mounted) return;
    result.when(
      success: (_) {
        ref.invalidate(fatteningFeedDashboardProvider(batchId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.fatteningPlanSaved)),
        );
      },
      failure: (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    this.subtitle,
  });

  final String label;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
