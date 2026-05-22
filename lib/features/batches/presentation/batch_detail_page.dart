import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/offline/network_errors.dart';
import '../../../routing/app_routes.dart';
import '../data/batch_dto.dart';
import '../data/batch_repository.dart';
import 'batch_providers.dart';
import 'widgets/batch_feedback.dart';
import 'widgets/batch_merge_dialog.dart';
import 'widgets/batch_move_dialog.dart';

class BatchDetailPage extends ConsumerWidget {
  const BatchDetailPage({super.key, required this.batchId});

  final String batchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final detailAsync = ref.watch(batchDetailProvider(batchId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.batchDetailTitle),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.batchEdit(batchId)),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => BatchFeedback.loading(),
        error: (e, _) => BatchFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.invalidate(batchDetailProvider(batchId)),
        ),
        data: (detail) => _BatchDetailBody(batchId: batchId, detail: detail),
      ),
    );
  }
}

class _BatchDetailBody extends ConsumerWidget {
  const _BatchDetailBody({required this.batchId, required this.detail});

  final String batchId;
  final BatchDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final batch = detail.batch;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (detail.fromCache) BatchFeedback.offlineHint(context),
        if (batch.pendingSync)
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: ListTile(
              leading: const Icon(Icons.sync_problem),
              title: Text(l10n.batchPendingSync),
              subtitle: batch.lastSyncError != null ? Text(batch.lastSyncError!) : null,
            ),
          ),
        Text(batch.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(l10n.batchAnimalCount(batch.animalCount)),
        if (batch.animalType != null) Text('${l10n.batchTypeLabel}: ${batch.animalType}'),
        if (batch.location != null && batch.location!.isNotEmpty)
          Text('${l10n.batchLocationLabel}: ${batch.location}'),
        if (batch.notes != null && batch.notes!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(batch.notes!),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final input = await showBatchMoveDialog(context, ref, fromBatchId: batchId);
                  if (input == null || !context.mounted) return;
                  final result = await ref.read(batchRepositoryProvider).moveAnimals(input);
                  result.when(
                    success: (_) {
                      ref.invalidate(batchDetailProvider(batchId));
                      ref.invalidate(batchListProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.batchMoveSuccess)),
                      );
                    },
                    failure: (e) {
                      final msg = e.code == offlineQueuedCode ? l10n.batchOfflineSaved : e.message;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                      ref.invalidate(batchDetailProvider(batchId));
                      ref.invalidate(batchListProvider);
                    },
                  );
                },
                icon: const Icon(Icons.swap_horiz),
                label: Text(l10n.batchMoveAction),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final input = await showBatchMergeDialog(context, ref, sourceBatchId: batchId);
                  if (input == null || !context.mounted) return;
                  final result = await ref.read(batchRepositoryProvider).mergeBatches(input);
                  result.when(
                    success: (merged) {
                      ref.invalidate(batchListProvider);
                      context.go(AppRoutes.batchDetail(merged.id));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.batchMergeSuccess)),
                      );
                    },
                    failure: (e) {
                      final msg = e.code == offlineQueuedCode ? l10n.batchOfflineSaved : e.message;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                      ref.invalidate(batchDetailProvider(batchId));
                      ref.invalidate(batchListProvider);
                    },
                  );
                },
                icon: const Icon(Icons.merge_type),
                label: Text(l10n.batchMergeAction),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(l10n.batchAnimalsTitle, style: Theme.of(context).textTheme.titleMedium),
        if (detail.animals.isEmpty)
          Text(l10n.batchNoAnimals)
        else
          ...detail.animals.map(
            (a) => ListTile(
              leading: const Icon(Icons.pets),
              title: Text(a.label),
              subtitle: a.animalType != null ? Text(a.animalType!) : null,
              onTap: () => context.push(AppRoutes.animalDetail(a.id)),
            ),
          ),
        const SizedBox(height: 16),
        Text(l10n.batchMovementsTitle, style: Theme.of(context).textTheme.titleMedium),
        if (batch.movements.isEmpty)
          Text(l10n.batchNoMovements)
        else
          ...batch.movements.reversed.map(
            (m) => ListTile(
              leading: Icon(m.type == 'MERGE' ? Icons.merge_type : Icons.swap_horiz),
              title: Text(m.type),
              subtitle: Text('${m.animalIds.length} animals · ${m.at.toLocal()}'),
            ),
          ),
      ],
    );
  }
}
