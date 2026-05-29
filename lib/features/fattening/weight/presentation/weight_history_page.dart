import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../routing/app_routes.dart';
import '../../presentation/fattening_providers.dart';
import '../../presentation/widgets/fattening_feedback.dart';
import '../data/weight_dto.dart';

class FatteningWeightHistoryPage extends ConsumerWidget {
  const FatteningWeightHistoryPage({
    super.key,
    required this.farmId,
    required this.batchId,
  });

  final String farmId;
  final String batchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final historyAsync = ref.watch(fatteningWeightHistoryProvider(batchId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.fatteningWeightHistory)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(
          AppRoutes.fatteningWeightEntry(farmId, batchId),
        ),
        child: const Icon(Icons.add),
      ),
      body: historyAsync.when(
        loading: FatteningFeedback.loading,
        error: (e, _) => FatteningFeedback.error(
          context,
          message: e.toString(),
          onRetry: () =>
              ref.invalidate(fatteningWeightHistoryProvider(batchId)),
        ),
        data: (history) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(fatteningWeightHistoryProvider(batchId));
              await ref.read(fatteningWeightHistoryProvider(batchId).future);
            },
            child: history.records.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(child: Text(l10n.fatteningNoWeightHistory)),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(8),
                    itemCount: history.records.length,
                    itemBuilder: (context, index) {
                      final r = history.records[index];
                      return _WeightHistoryTile(record: r);
                    },
                  ),
          );
        },
      ),
    );
  }
}

class _WeightHistoryTile extends StatelessWidget {
  const _WeightHistoryTile({required this.record});

  final WeightRecord record;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final methodLabel = switch (record.method) {
      WeightRecordMethod.tape => l10n.fatteningWeightMethodTape,
      WeightRecordMethod.estimate => l10n.fatteningWeightMethodEstimate,
      WeightRecordMethod.other => l10n.fatteningWeightMethodOther,
      WeightRecordMethod.scale => l10n.fatteningWeightMethodScale,
    };
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.monitor_weight_outlined),
        title: Text(
          '${record.animalName ?? record.animalId} — ${record.weightKg} kg',
        ),
        subtitle: Text(
          '${record.recordedOn} · $methodLabel'
          '${record.note != null && record.note!.isNotEmpty ? '\n${record.note}' : ''}',
        ),
        trailing: record.pendingSync
            ? Icon(
                Icons.cloud_upload_outlined,
                color: Theme.of(context).colorScheme.error,
                size: 20,
              )
            : null,
      ),
    );
  }
}
