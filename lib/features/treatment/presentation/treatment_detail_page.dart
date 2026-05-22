import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import 'treatment_providers.dart';
import 'widgets/medicine_card.dart';
import 'widgets/treatment_labels.dart';

class TreatmentDetailPage extends ConsumerWidget {
  const TreatmentDetailPage({super.key, required this.treatmentId});

  final String treatmentId;

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
            onPressed: () => context.push(AppRoutes.treatmentEdit(treatmentId)),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: treatmentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (treatment) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (treatment.fromCache)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(l10n.treatmentOfflineHint, style: Theme.of(context).textTheme.bodySmall),
                ),
              Text(treatment.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('${treatmentStatusLabel(l10n, treatment.status)} · ${treatment.targetLabel}'),
              if (treatment.diagnosis != null) ...[
                const SizedBox(height: 16),
                Text(l10n.treatmentDiagnosisLabel, style: Theme.of(context).textTheme.titleSmall),
                Text(treatment.diagnosis!),
              ],
              const SizedBox(height: 16),
              Text(l10n.treatmentPrescriptionTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              prescriptionAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(e.toString()),
                data: (prescription) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (prescription.prescription != null && prescription.prescription!.isNotEmpty)
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
                Text(l10n.treatmentNotesLabel, style: Theme.of(context).textTheme.titleSmall),
                Text(treatment.notes!),
              ],
            ],
          );
        },
      ),
    );
  }
}
