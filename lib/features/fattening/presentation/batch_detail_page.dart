import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import '../../offline/data/connectivity_service.dart';
import '../../offline/offline_providers.dart';
import '../data/fattening_batch_dto.dart';
import '../data/fattening_repository.dart';
import 'fattening_providers.dart';
import 'widgets/fattening_feedback.dart';
import '../weight/presentation/widgets/animal_weight_card.dart';
import 'widgets/fattening_status_chip.dart';

class FatteningBatchDetailPage extends ConsumerWidget {
  const FatteningBatchDetailPage({
    super.key,
    required this.farmId,
    required this.batchId,
  });

  final String farmId;
  final String batchId;

  Future<void> _startBatch(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final online = isOnlineMode(ref.read(connectivityServiceProvider).currentMode);
    if (!online) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fatteningStartRequiresOnline)),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.fatteningStartConfirmTitle),
        content: Text(l10n.fatteningStartConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.fatteningStartBatch),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(fatteningRepositoryProvider)
        .startBatch(batchId);
    if (!context.mounted) return;
    result.when(
      success: (_) {
        refreshFatteningAfterMutation(ref, farmId: farmId, batchId: batchId);
        ref.invalidate(fatteningBatchDetailProvider(batchId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.fatteningStartedSuccess)),
        );
      },
      failure: (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final detailAsync = ref.watch(fatteningBatchDetailProvider(batchId));
    final progressAsync = ref.watch(fatteningBatchProgressProvider(batchId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.fatteningBatchDetail)),
      body: detailAsync.when(
        loading: () => FatteningFeedback.loading(),
        error: (e, _) => FatteningFeedback.error(
          context,
          error: e,
          onRetry: () => ref.invalidate(fatteningBatchDetailProvider(batchId)),
          onRefresh: () async {
            ref.invalidate(fatteningBatchDetailProvider(batchId));
            await ref.read(fatteningBatchDetailProvider(batchId).future);
          },
          onOpenCached: () async {
            final cached = await ref
                .read(fatteningRepositoryProvider)
                .readCachedDetail(batchId);
            if (cached != null && context.mounted) {
              ref.invalidate(fatteningBatchDetailProvider(batchId));
            }
          },
        ),
        data: (detail) {
          final batch = detail.batch;
          final isDraft = batch.status.isDraft;
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(fatteningBatchDetailProvider(batchId));
              await ref.read(fatteningBatchDetailProvider(batchId).future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (detail.fromCache) FatteningFeedback.offlineHint(context),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        batch.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    FatteningStatusChip(status: batch.status),
                    if (batch.goalType.isQurbani) ...[
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(l10n.fatteningGoalTypeQurbani),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ],
                ),
                if (batch.goal != null && batch.goal!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(batch.goal!),
                ],
                if (batch.startDate != null) ...[
                  const SizedBox(height: 8),
                  Text('${l10n.fatteningStartDate}: ${_formatDate(batch.startDate!)}'),
                ],
                if (batch.targetDate != null) ...[
                  const SizedBox(height: 4),
                  Text('${l10n.fatteningTargetDate}: ${_formatDate(batch.targetDate!)}'),
                ],
                const SizedBox(height: 16),
                Text(
                  l10n.fatteningAnimalsInBatch(detail.animals.length),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (detail.animals.isEmpty)
                  Text(l10n.fatteningNoAnimalsYet)
                else if (!isDraft &&
                    progressAsync.hasValue &&
                    progressAsync.value!.progress.isNotEmpty)
                  ...progressAsync.value!.progress.map(
                    (p) => AnimalWeightCard(
                      progress: p,
                      compact: true,
                      onRecord: batch.status.isActive
                          ? () => context.push(
                              AppRoutes.fatteningWeightEntry(
                                farmId,
                                batchId,
                                animalId: p.animalId,
                              ),
                            )
                          : null,
                    ),
                  )
                else
                  ...detail.animals.map(
                    (animal) => ListTile(
                      leading: CircleAvatar(
                        child: Text(animal.name.isNotEmpty ? animal.name[0] : '?'),
                      ),
                      title: Text(animal.name),
                      subtitle: Text(
                        [
                          if (animal.animalType != null) animal.animalType,
                          if (animal.weightKg != null) '${animal.weightKg} kg',
                        ].whereType<String>().join(' · '),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                if (isDraft) ...[
                  OutlinedButton.icon(
                    onPressed: () => context.push(
                      AppRoutes.fatteningAddAnimals(farmId, batchId),
                    ),
                    icon: const Icon(Icons.pets_outlined),
                    label: Text(l10n.fatteningAddAnimals),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: detail.animals.isEmpty
                        ? null
                        : () => _startBatch(context, ref),
                    icon: const Icon(Icons.play_arrow_outlined),
                    label: Text(l10n.fatteningStartBatch),
                  ),
                ] else if (batch.status.isActive ||
                    batch.status == FatteningBatchStatus.completed) ...[
                  FilledButton.icon(
                    onPressed: () => context.push(
                      AppRoutes.fatteningBatchProgress(farmId, batchId),
                    ),
                    icon: const Icon(Icons.trending_up_outlined),
                    label: Text(l10n.fatteningProgressTitle),
                  ),
                  const SizedBox(height: 12),
                  if (batch.status.isActive)
                    OutlinedButton.icon(
                      onPressed: () => context.push(
                        AppRoutes.fatteningWeightEntry(farmId, batchId),
                      ),
                      icon: const Icon(Icons.monitor_weight_outlined),
                      label: Text(l10n.fatteningRecordWeight),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.push(
                      AppRoutes.fatteningBatchFeed(farmId, batchId),
                    ),
                    icon: const Icon(Icons.restaurant_outlined),
                    label: Text(l10n.fatteningFeedDashboardTitle),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.push(
                      AppRoutes.fatteningBatchRoi(farmId, batchId),
                    ),
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    label: Text(l10n.fatteningRoiTitle),
                  ),
                  if (batch.goalType.isQurbani) ...[
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: () => context.push(
                        AppRoutes.fatteningBatchQurbani(farmId, batchId),
                      ),
                      icon: const Icon(Icons.mosque_outlined),
                      label: Text(l10n.fatteningQurbaniTitle),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
