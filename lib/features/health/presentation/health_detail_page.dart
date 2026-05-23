import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/navigation/navigation_guard.dart';
import '../../../core/offline/network_errors.dart';
import '../../../routing/app_routes.dart';
import '../data/health_repository.dart';
import 'health_navigation.dart';
import 'health_providers.dart';
import 'widgets/health_feedback.dart';
import 'widgets/health_labels.dart';

class HealthDetailPage extends ConsumerWidget {
  const HealthDetailPage({super.key, required this.recordId});

  final String recordId;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.healthDeleteTitle),
        content: Text(l10n.healthDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.healthDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(healthRepositoryProvider)
        .deleteRecord(recordId);
    if (!context.mounted) return;
    result.when(
      success: (_) {
        HealthNavigation.afterDelete(ref);
        context.pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.healthDeleteSuccess)));
      },
      failure: (e) {
        if (e.code == offlineQueuedCode) {
          HealthNavigation.afterDelete(ref);
          context.pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.healthOfflineSaved)));
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
    final recordAsync = ref.watch(healthRecordProvider(recordId));

    return Scaffold(
      appBar: safeAppBar(
        context,
        title: Text(l10n.healthDetailTitle),
        actions: [
          IconButton(
            onPressed: () => _delete(context, ref),
            icon: const Icon(Icons.delete_outline),
          ),
          IconButton(
            onPressed: () => context.push(AppRoutes.healthEdit(recordId)),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: recordAsync.when(
        loading: HealthFeedback.loading,
        error: (e, _) => HealthFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.invalidate(healthRecordProvider(recordId)),
        ),
        data: (event) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (event.fromCache)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: HealthFeedback.offlineHint(context),
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  event.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                subtitle: Text(healthEventTypeLabel(l10n, event.eventType)),
              ),
              const Divider(),
              _DetailRow(
                label: l10n.healthAnimalLabel,
                value: event.targetLabel,
              ),
              _DetailRow(
                label: l10n.healthDateLabel,
                value: event.recordedDate.toLocal().toString().split(' ').first,
              ),
              if (event.symptoms != null)
                _DetailRow(
                  label: l10n.healthSymptomsLabel,
                  value: event.symptoms!,
                ),
              if (event.diagnosis != null)
                _DetailRow(
                  label: l10n.healthDiagnosisLabel,
                  value: event.diagnosis!,
                ),
              if (event.diseaseName != null)
                _DetailRow(
                  label: l10n.healthDiseaseLabel,
                  value: event.diseaseName!,
                ),
              if (event.notes != null)
                _DetailRow(label: l10n.healthNotesLabel, value: event.notes!),
              if (event.treatmentRefId != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.healthTreatmentLinkLabel),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(
                    AppRoutes.treatmentDetail(event.treatmentRefId!),
                  ),
                ),
              if (event.vaccineRefId != null)
                _DetailRow(
                  label: l10n.healthVaccineRefLabel,
                  value: event.vaccineRefId!,
                ),
              if (event.pendingSync)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Chip(label: Text(l10n.healthPendingSync)),
                ),
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
