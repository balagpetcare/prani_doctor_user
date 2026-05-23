import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/offline/network_errors.dart';
import '../../../routing/app_routes.dart';
import '../data/treatment_repository.dart';
import 'treatment_navigation.dart';
import 'treatment_providers.dart';
import 'widgets/medicine_card.dart';
import 'widgets/treatment_feedback.dart';
import 'widgets/treatment_labels.dart';

class TreatmentDetailPage extends ConsumerWidget {
  const TreatmentDetailPage({super.key, required this.treatmentId});

  final String treatmentId;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.treatmentDeleteTitle),
        content: Text(l10n.treatmentDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.treatmentDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(treatmentRepositoryProvider)
        .deleteRecord(treatmentId);
    if (!context.mounted) return;
    result.when(
      success: (_) {
        TreatmentNavigation.afterDelete(ref);
        context.pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.treatmentDeleteSuccess)));
      },
      failure: (e) {
        if (e.code == offlineQueuedCode) {
          TreatmentNavigation.afterDelete(ref);
          context.pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.treatmentOfflineSaved)));
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
    final treatmentAsync = ref.watch(treatmentRecordProvider(treatmentId));
    final prescriptionAsync = ref.watch(prescriptionProvider(treatmentId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.treatmentDetailTitle),
        actions: [
          IconButton(
            onPressed: () => _delete(context, ref),
            icon: const Icon(Icons.delete_outline),
          ),
          IconButton(
            onPressed: () => context.push(AppRoutes.treatmentEdit(treatmentId)),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: treatmentAsync.when(
        loading: TreatmentFeedback.loading,
        error: (e, _) => TreatmentFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.invalidate(treatmentRecordProvider(treatmentId)),
        ),
        data: (treatment) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (treatment.fromCache) TreatmentFeedback.offlineHint(context),
              Text(
                treatment.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '${treatmentStatusLabel(l10n, treatment.status)} · ${treatment.targetLabel}',
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.treatmentStartDateLabel),
                subtitle: Text(
                  treatment.startDate.toLocal().toString().split(' ').first,
                ),
              ),
              if (treatment.endDate != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.treatmentEndDateLabel),
                  subtitle: Text(
                    treatment.endDate!.toLocal().toString().split(' ').first,
                  ),
                ),
              if (treatment.diagnosis != null) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.treatmentDiagnosisLabel,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(treatment.diagnosis!),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.treatmentPrescriptionTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push(
                      AppRoutes.treatmentPrescription(treatmentId),
                    ),
                    child: Text(l10n.treatmentViewPrescription),
                  ),
                ],
              ),
              prescriptionAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(e.toString()),
                data: (prescription) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (prescription.prescription != null &&
                          prescription.prescription!.isNotEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(prescription.prescription!),
                          ),
                        ),
                      if (prescription.medicines.isEmpty)
                        Text(l10n.treatmentNoMedicines)
                      else
                        ...prescription.medicines.map(
                          (m) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: MedicineCard(medicine: m),
                          ),
                        ),
                    ],
                  );
                },
              ),
              if (treatment.notes != null) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.treatmentNotesLabel,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(treatment.notes!),
              ],
              if (treatment.pendingSync)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Chip(label: Text(l10n.treatmentPendingSync)),
                ),
            ],
          );
        },
      ),
    );
  }
}
