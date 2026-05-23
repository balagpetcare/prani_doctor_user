import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../data/treatment_dto.dart';

class MedicineCard extends StatelessWidget {
  const MedicineCard({super.key, required this.medicine});

  final MedicineItem medicine;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(medicine.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('${l10n.treatmentDosageLabel}: ${medicine.dosage}'),
            if (medicine.frequency != null)
              Text('${l10n.treatmentFrequencyLabel}: ${medicine.frequency}'),
            if (medicine.durationDays != null)
              Text(
                '${l10n.treatmentDurationLabel}: ${medicine.durationDays} ${l10n.treatmentDaysSuffix}',
              ),
          ],
        ),
      ),
    );
  }
}
