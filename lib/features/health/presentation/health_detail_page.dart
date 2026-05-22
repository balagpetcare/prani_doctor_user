import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import 'health_providers.dart';
import 'widgets/health_labels.dart';

class HealthDetailPage extends ConsumerWidget {
  const HealthDetailPage({super.key, required this.recordId});

  final String recordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final recordAsync = ref.watch(healthRecordProvider(recordId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.healthDetailTitle),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.healthEdit(recordId)),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: recordAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (event) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (event.fromCache)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(l10n.healthOfflineHint, style: Theme.of(context).textTheme.bodySmall),
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(event.title, style: Theme.of(context).textTheme.titleLarge),
                subtitle: Text(healthEventTypeLabel(l10n, event.eventType)),
              ),
              const Divider(),
              _DetailRow(label: l10n.healthAnimalLabel, value: event.targetLabel),
              _DetailRow(label: l10n.healthDateLabel, value: event.recordedDate.toLocal().toString().split(' ').first),
              if (event.symptoms != null) _DetailRow(label: l10n.healthSymptomsLabel, value: event.symptoms!),
              if (event.diagnosis != null) _DetailRow(label: l10n.healthDiagnosisLabel, value: event.diagnosis!),
              if (event.diseaseName != null) _DetailRow(label: l10n.healthDiseaseLabel, value: event.diseaseName!),
              if (event.notes != null) _DetailRow(label: l10n.healthNotesLabel, value: event.notes!),
              if (event.pendingSync)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Chip(label: Text(l10n.healthPendingSync)),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}
