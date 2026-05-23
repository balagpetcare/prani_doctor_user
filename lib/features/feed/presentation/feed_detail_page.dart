import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/navigation/navigation_guard.dart';
import '../../../core/offline/network_errors.dart';
import '../../../routing/app_routes.dart';
import '../data/feed_dto.dart';
import '../data/feed_repository.dart';
import 'feed_navigation.dart';
import 'feed_providers.dart';
import 'widgets/feed_feedback.dart';

class FeedDetailPage extends ConsumerWidget {
  const FeedDetailPage({super.key, required this.recordId});

  final String recordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final recordAsync = ref.watch(feedRecordProvider(recordId));

    return Scaffold(
      appBar: safeAppBar(
        context,
        title: Text(l10n.feedDetailTitle),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.feedEdit(recordId)),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: recordAsync.when(
        loading: FeedFeedback.loading,
        error: (e, _) => FeedFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => FeedNavigation.refreshDetail(ref, recordId),
        ),
        data: (record) => RefreshIndicator(
          onRefresh: () => FeedNavigation.refreshDetail(ref, recordId),
          child: _FeedDetailBody(record: record),
        ),
      ),
    );
  }
}

class _FeedDetailBody extends ConsumerWidget {
  const _FeedDetailBody({required this.record});

  final FeedRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        if (record.fromCache) FeedFeedback.offlineHint(context),
        if (record.pendingSync)
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: ListTile(
              leading: const Icon(Icons.sync_problem),
              title: Text(l10n.feedPendingSync),
            ),
          ),
        Text(
          '${record.feedType.apiValue} · ${record.targetLabel}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text('${record.amount.toStringAsFixed(2)} ${record.unit.apiValue}'),
        if (record.costBdt != null) Text(l10n.feedCostValue(record.costBdt!)),
        Text(
          '${l10n.feedDateLabel}: ${record.recordedDate.toLocal().toString().split(' ').first}',
        ),
        if (record.farmRef != null && record.farmRef!.isNotEmpty)
          Text('${l10n.feedFarmLabel}: ${record.farmRef}'),
        if (record.notes != null && record.notes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(record.notes!),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => context.push(AppRoutes.feedEdit(record.id)),
          icon: const Icon(Icons.edit_outlined),
          label: Text(l10n.feedEditTitle),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(l10n.feedDeleteTitle),
                content: Text(l10n.feedDeleteConfirm),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l10n.cancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l10n.feedDeleteAction),
                  ),
                ],
              ),
            );
            if (confirmed != true || !context.mounted) return;
            final result = await ref
                .read(feedRepositoryProvider)
                .deleteRecord(record.id);
            if (!context.mounted) return;
            result.when(
              success: (_) {
                FeedNavigation.afterDelete(ref);
                context.go(AppRoutes.feeds);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.feedDeleteSuccess)));
              },
              failure: (e) {
                final msg = e.code == offlineQueuedCode
                    ? l10n.feedOfflineSaved
                    : e.message;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(msg)));
                if (e.code == offlineQueuedCode) {
                  FeedNavigation.afterDelete(ref);
                  context.go(AppRoutes.feeds);
                }
              },
            );
          },
          icon: const Icon(Icons.delete_outline),
          label: Text(l10n.feedDeleteAction),
        ),
      ],
    );
  }
}
