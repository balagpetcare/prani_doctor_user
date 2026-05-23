import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import 'treatment_providers.dart';
import 'widgets/medicine_card.dart';
import 'widgets/treatment_feedback.dart';

class TreatmentPrescriptionPage extends ConsumerWidget {
  const TreatmentPrescriptionPage({super.key, required this.treatmentId});

  final String treatmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final prescriptionAsync = ref.watch(prescriptionProvider(treatmentId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.treatmentPrescriptionTitle)),
      body: prescriptionAsync.when(
        loading: TreatmentFeedback.loading,
        error: (e, _) => TreatmentFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.invalidate(prescriptionProvider(treatmentId)),
        ),
        data: (prescription) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (prescription.fromCache)
                TreatmentFeedback.offlineHint(context),
              if (prescription.prescription != null &&
                  prescription.prescription!.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(prescription.prescription!),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                l10n.treatmentMedicinesTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (prescription.medicines.isEmpty)
                Text(l10n.treatmentNoMedicines)
              else
                ...prescription.medicines.map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: MedicineCard(medicine: m),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
