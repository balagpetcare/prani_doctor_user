import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../routing/app_routes.dart';
import '../../data/treatment_dto.dart';
import 'treatment_labels.dart';

class TreatmentRecordCard extends StatelessWidget {
  const TreatmentRecordCard({super.key, required this.record});

  final FarmTreatment record;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.medication_outlined),
        title: Text('${record.title} · ${record.targetLabel}'),
        subtitle: Text(
          [
            treatmentStatusLabel(l10n, record.status),
            record.startDate.toLocal().toString().split(' ').first,
            if (record.medicines.isNotEmpty)
              l10n.treatmentMedicineCount(record.medicines.length),
            if (record.pendingSync) l10n.treatmentPendingSync,
          ].join(' · '),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(AppRoutes.treatmentDetail(record.id)),
      ),
    );
  }
}
