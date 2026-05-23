import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../routing/app_routes.dart';
import '../../data/vaccine_dto.dart';
import 'vaccine_labels.dart';

class VaccineRecordCard extends StatelessWidget {
  const VaccineRecordCard({super.key, required this.record});

  final VaccineRecord record;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.vaccines_outlined),
        title: Text('${record.vaccineName} · ${record.targetLabel}'),
        subtitle: Text(
          [
            vaccineStatusLabel(l10n, record.status),
            record.scheduledDate.toLocal().toString().split(' ').first,
            if (record.pendingSync) l10n.vaccinePendingSync,
          ].join(' · '),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(AppRoutes.vaccineDetail(record.id)),
      ),
    );
  }
}
