import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/offline/network_errors.dart';
import '../../../routing/app_routes.dart';
import '../data/vaccine_repository.dart';
import 'vaccine_navigation.dart';
import 'vaccine_providers.dart';
import 'widgets/vaccine_feedback.dart';
import 'widgets/vaccine_labels.dart';

class VaccineDetailPage extends ConsumerWidget {
  const VaccineDetailPage({super.key, required this.recordId});

  final String recordId;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.vaccineDeleteTitle),
        content: Text(l10n.vaccineDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.vaccineDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(vaccineRepositoryProvider)
        .deleteRecord(recordId);
    if (!context.mounted) return;
    result.when(
      success: (_) {
        VaccineNavigation.afterDelete(ref);
        context.pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.vaccineDeleteSuccess)));
      },
      failure: (e) {
        if (e.code == offlineQueuedCode) {
          VaccineNavigation.afterDelete(ref);
          context.pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.vaccineOfflineSaved)));
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final recordAsync = ref.watch(vaccineRecordProvider(recordId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.vaccineDetailTitle),
        actions: [
          IconButton(
            onPressed: () => _delete(context, ref),
            icon: const Icon(Icons.delete_outline),
          ),
          IconButton(
            onPressed: () => context.push(AppRoutes.vaccineEdit(recordId)),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: recordAsync.when(
        loading: VaccineFeedback.loading,
        error: (e, _) => VaccineFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.invalidate(vaccineRecordProvider(recordId)),
        ),
        data: (record) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (record.fromCache) VaccineFeedback.offlineHint(context),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  record.vaccineName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                subtitle: Text(vaccineStatusLabel(l10n, record.status)),
              ),
              const Divider(),
              _DetailRow(
                label: l10n.vaccineAnimalLabel,
                value: record.targetLabel,
              ),
              _DetailRow(
                label: l10n.vaccineScheduledDateLabel,
                value: record.scheduledDate
                    .toLocal()
                    .toString()
                    .split(' ')
                    .first,
              ),
              if (record.administeredDate != null)
                _DetailRow(
                  label: l10n.vaccineAdministeredDateLabel,
                  value: record.administeredDate!
                      .toLocal()
                      .toString()
                      .split(' ')
                      .first,
                ),
              if (record.nextDueDate != null)
                _DetailRow(
                  label: l10n.vaccineNextDueLabel,
                  value: record.nextDueDate!
                      .toLocal()
                      .toString()
                      .split(' ')
                      .first,
                ),
              if (record.vaccineType != null)
                _DetailRow(
                  label: l10n.vaccineTypeLabel,
                  value: record.vaccineType!,
                ),
              if (record.batchNumber != null)
                _DetailRow(
                  label: l10n.vaccineBatchLabel,
                  value: record.batchNumber!,
                ),
              if (record.notes != null)
                _DetailRow(label: l10n.vaccineNotesLabel, value: record.notes!),
              if (record.pendingSync)
                Chip(label: Text(l10n.vaccinePendingSync)),
            ],
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}
