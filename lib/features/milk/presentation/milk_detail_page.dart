import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/offline/network_errors.dart';
import '../../../routing/app_routes.dart';
import '../data/milk_dto.dart';
import '../data/milk_repository.dart';
import 'milk_navigation.dart';
import 'milk_providers.dart';
import 'widgets/milk_feedback.dart';

class MilkDetailPage extends ConsumerWidget {
  const MilkDetailPage({super.key, required this.recordId});

  final String recordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final recordAsync = ref.watch(milkRecordProvider(recordId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.milkDetailTitle),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.milkEdit(recordId)),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: recordAsync.when(
        loading: MilkFeedback.loading,
        error: (e, _) => MilkFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => MilkNavigation.refreshDetail(ref, recordId),
        ),
        data: (record) => RefreshIndicator(
          onRefresh: () => MilkNavigation.refreshDetail(ref, recordId),
          child: _MilkDetailBody(record: record),
        ),
      ),
    );
  }
}

class _MilkDetailBody extends ConsumerWidget {
  const _MilkDetailBody({required this.record});

  final MilkRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final sessionLabel = record.session == MilkSession.morning
        ? l10n.milkSessionMorning
        : l10n.milkSessionEvening;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        if (record.fromCache) MilkFeedback.offlineHint(context),
        if (record.pendingSync)
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: ListTile(
              leading: const Icon(Icons.sync_problem),
              title: Text(l10n.milkPendingSync),
            ),
          ),
        Text(
          record.animalName.isNotEmpty ? record.animalName : record.animalId,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text('${record.quantityLiters.toStringAsFixed(2)} L · $sessionLabel'),
        Text(
          '${l10n.milkDateLabel}: ${record.recordedDate.toLocal().toString().split(' ').first}',
        ),
        if (record.farmRef != null && record.farmRef!.isNotEmpty)
          Text('${l10n.milkFarmLabel}: ${record.farmRef}'),
        if (record.notes != null && record.notes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(record.notes!),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => context.push(AppRoutes.milkEdit(record.id)),
          icon: const Icon(Icons.edit_outlined),
          label: Text(l10n.milkEditTitle),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(l10n.milkDeleteTitle),
                content: Text(l10n.milkDeleteConfirm),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l10n.cancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l10n.milkDeleteAction),
                  ),
                ],
              ),
            );
            if (confirmed != true || !context.mounted) return;
            final result = await ref
                .read(milkRepositoryProvider)
                .deleteRecord(record.id);
            if (!context.mounted) return;
            result.when(
              success: (_) async {
                await MilkNavigation.afterDelete(ref);
                context.go(AppRoutes.milk);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.milkDeleteSuccess)));
              },
              failure: (e) {
                final msg = e.code == offlineQueuedCode
                    ? l10n.milkOfflineSaved
                    : e.message;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(msg)));
                if (e.code == offlineQueuedCode) {
                  MilkNavigation.afterDelete(ref);
                  context.go(AppRoutes.milk);
                }
              },
            );
          },
          icon: const Icon(Icons.delete_outline),
          label: Text(l10n.milkDeleteAction),
        ),
      ],
    );
  }
}
