import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import '../data/fattening_batch_dto.dart';
import 'fattening_providers.dart';
import 'widgets/fattening_batch_card.dart';
import 'widgets/fattening_feedback.dart';

class FatteningBatchListPage extends ConsumerWidget {
  const FatteningBatchListPage({super.key, required this.farmId});

  final String farmId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final listAsync = ref.watch(fatteningBatchListProvider(farmId));
    final statusFilter = ref.watch(fatteningStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.fatteningListTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.fatteningCreate(farmId)),
        icon: const Icon(Icons.add),
        label: Text(l10n.fatteningCreateBatch),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: Text(l10n.fatteningFilterAll),
                  selected: statusFilter == null,
                  onSelected: (_) {
                    ref.read(fatteningStatusFilterProvider.notifier).state =
                        null;
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(l10n.fatteningFilterDraft),
                  selected: statusFilter == FatteningBatchStatus.draft,
                  onSelected: (_) {
                    ref.read(fatteningStatusFilterProvider.notifier).state =
                        FatteningBatchStatus.draft;
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(l10n.fatteningFilterActive),
                  selected: statusFilter == FatteningBatchStatus.active,
                  onSelected: (_) {
                    ref.read(fatteningStatusFilterProvider.notifier).state =
                        FatteningBatchStatus.active;
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: listAsync.when(
              loading: () => FatteningFeedback.loading(),
              error: (e, _) => FatteningFeedback.error(
                context,
                error: e,
                onRetry: () => ref
                    .read(fatteningBatchListProvider(farmId).notifier)
                    .refresh(),
                onRefresh: () => ref
                    .read(fatteningBatchListProvider(farmId).notifier)
                    .refresh(),
              ),
              data: (state) {
                if (state.batches.isEmpty) {
                  return FatteningFeedback.empty(
                    context,
                    onCreate: () =>
                        context.push(AppRoutes.fatteningCreate(farmId)),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref
                      .read(fatteningBatchListProvider(farmId).notifier)
                      .refresh(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount:
                        state.batches.length + (state.fromCache ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (state.fromCache && index == 0) {
                        return FatteningFeedback.offlineHint(context);
                      }
                      final batchIndex = state.fromCache ? index - 1 : index;
                      final batch = state.batches[batchIndex];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: FatteningBatchCard(
                          batch: batch,
                          onTap: () => context.push(
                            AppRoutes.fatteningBatchDetail(farmId, batch.id),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
