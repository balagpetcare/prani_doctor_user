import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../routing/app_routes.dart';
import '../../data/health_dto.dart';
import 'health_labels.dart';

class HealthEventCard extends StatelessWidget {
  const HealthEventCard({super.key, required this.event});

  final HealthEvent event;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.medical_services_outlined),
        title: Text('${healthEventTypeLabel(l10n, event.eventType)} · ${event.title}'),
        subtitle: Text(
          [
            event.targetLabel,
            event.recordedDate.toLocal().toString().split(' ').first,
            if (event.pendingSync) l10n.healthPendingSync,
          ].join(' · '),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(AppRoutes.healthDetail(event.id)),
      ),
    );
  }
}
