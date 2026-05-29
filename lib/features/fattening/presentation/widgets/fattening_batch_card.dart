import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../data/fattening_batch_dto.dart';
import 'fattening_status_chip.dart';

class FatteningBatchCard extends StatelessWidget {
  const FatteningBatchCard({
    super.key,
    required this.batch,
    required this.onTap,
  });

  final FatteningBatch batch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(batch.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (batch.goalType.isQurbani)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Chip(
                      label: Text(l10n.fatteningGoalTypeQurbani),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                if (batch.goal != null && batch.goal!.isNotEmpty)
                  Expanded(
                    child: Text(
                      batch.goal!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            Text('${batch.animalCount} animals'),
            if (batch.pendingSync)
              Text(
                'Pending sync',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: FatteningStatusChip(status: batch.status),
      ),
    );
  }
}
