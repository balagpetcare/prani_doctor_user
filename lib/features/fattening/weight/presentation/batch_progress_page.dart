import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../routing/app_routes.dart';
import '../../../milk/presentation/widgets/milk_simple_chart.dart';
import '../../data/fattening_batch_dto.dart';
import '../../presentation/fattening_providers.dart';
import '../../presentation/widgets/fattening_feedback.dart';
import 'widgets/animal_weight_card.dart';

class FatteningBatchProgressPage extends ConsumerWidget {
  const FatteningBatchProgressPage({
    super.key,
    required this.farmId,
    required this.batchId,
  });

  final String farmId;
  final String batchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final progressAsync = ref.watch(fatteningBatchProgressProvider(batchId));
    final detailAsync = ref.watch(fatteningBatchDetailProvider(batchId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.fatteningProgressTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: l10n.fatteningWeightHistory,
            onPressed: () => context.push(
              AppRoutes.fatteningWeightHistory(farmId, batchId),
            ),
          ),
        ],
      ),
      floatingActionButton: detailAsync.maybeWhen(
        data: (detail) => detail.batch.status.isActive
            ? FloatingActionButton.extended(
                onPressed: () => context.push(
                  AppRoutes.fatteningWeightEntry(farmId, batchId),
                ),
                icon: const Icon(Icons.add),
                label: Text(l10n.fatteningRecordWeight),
              )
            : null,
        orElse: () => null,
      ),
      body: progressAsync.when(
        loading: FatteningFeedback.loading,
        error: (e, _) => FatteningFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.invalidate(fatteningBatchProgressProvider(batchId)),
        ),
        data: (snapshot) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(fatteningBatchProgressProvider(batchId));
              await ref.read(fatteningBatchProgressProvider(batchId).future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (snapshot.fromCache) FatteningFeedback.offlineHint(context),
                if (snapshot.avgCurrentWeightKg != null ||
                    snapshot.totalGainKg != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          if (snapshot.avgCurrentWeightKg != null)
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    l10n.fatteningAvgCurrentWeight,
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                  ),
                                  Text(
                                    '${snapshot.avgCurrentWeightKg!.toStringAsFixed(1)} kg',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge,
                                  ),
                                ],
                              ),
                            ),
                          if (snapshot.totalGainKg != null)
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    l10n.fatteningTotalGain,
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                  ),
                                  Text(
                                    '+${snapshot.totalGainKg!.toStringAsFixed(1)} kg',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  l10n.fatteningProgressSummary,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (snapshot.progress.isEmpty)
                  Text(l10n.fatteningNoProgressYet)
                else
                  ...snapshot.progress.map(
                    (p) => AnimalWeightCard(
                      progress: p,
                      onRecord: () => context.push(
                        AppRoutes.fatteningWeightEntry(
                          farmId,
                          batchId,
                          animalId: p.animalId,
                        ),
                      ),
                    ),
                  ),
                if (snapshot.growth.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    l10n.fatteningGrowthChart,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  MilkSimpleBarChart(
                    labels: snapshot.growth
                        .map((g) => g.recordedOn.length >= 5
                            ? g.recordedOn.substring(5)
                            : g.recordedOn)
                        .toList(),
                    values: snapshot.growth.map((g) => g.avgWeightKg).toList(),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
