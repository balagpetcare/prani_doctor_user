import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../routing/app_routes.dart';
import '../../data/milk_dto.dart';

class MilkEntryCard extends StatelessWidget {
  const MilkEntryCard({super.key, required this.record});

  final MilkRecord record;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sessionLabel = record.session == MilkSession.morning
        ? l10n.milkSessionMorning
        : l10n.milkSessionEvening;

    return Card(
      child: ListTile(
        leading: Icon(
          record.session == MilkSession.morning
              ? Icons.wb_sunny_outlined
              : Icons.nights_stay_outlined,
        ),
        title: Text(
          '${record.animalName.isNotEmpty ? record.animalName : record.animalId} · $sessionLabel',
        ),
        subtitle: Text(
          [
            '${record.quantityLiters.toStringAsFixed(2)} L',
            record.recordedDate.toLocal().toString().split(' ').first,
            if (record.farmRef != null && record.farmRef!.isNotEmpty)
              record.farmRef!,
            if (record.pendingSync) l10n.milkPendingSync,
          ].join(' · '),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(AppRoutes.milkDetail(record.id)),
      ),
    );
  }
}
