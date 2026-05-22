import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../routing/app_routes.dart';
import '../../data/feed_dto.dart';

class FeedEntryCard extends StatelessWidget {
  const FeedEntryCard({super.key, required this.record});

  final FeedRecord record;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.grass_outlined),
        title: Text('${record.feedType.apiValue} · ${record.targetLabel}'),
        subtitle: Text(
          [
            '${record.amount.toStringAsFixed(2)} ${record.unit.apiValue}',
            if (record.costBdt != null) l10n.feedCostValue(record.costBdt!),
            record.recordedDate.toLocal().toString().split(' ').first,
            if (record.pendingSync) l10n.feedPendingSync,
          ].join(' · '),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(AppRoutes.feedEdit(record.id)),
      ),
    );
  }
}
