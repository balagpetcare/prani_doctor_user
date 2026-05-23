import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../data/health_dto.dart';

class HealthSummarySection extends StatelessWidget {
  const HealthSummarySection({super.key, required this.summary});

  final HealthSummaryData summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _SummaryCard(
            label: l10n.healthSummaryTotal,
            value: '${summary.totalEvents}',
            icon: Icons.medical_services_outlined,
            color: theme.colorScheme.primary,
          ),
          _SummaryCard(
            label: l10n.healthSummaryDisease,
            value: '${summary.diseaseEvents}',
            icon: Icons.coronavirus_outlined,
            color: theme.colorScheme.error,
          ),
          _SummaryCard(
            label: l10n.healthSummaryCheckup,
            value: '${summary.checkupEvents}',
            icon: Icons.health_and_safety_outlined,
            color: theme.colorScheme.tertiary,
          ),
          _SummaryCard(
            label: l10n.healthSummaryTreatment,
            value: '${summary.treatmentEvents}',
            icon: Icons.healing_outlined,
            color: theme.colorScheme.secondary,
          ),
          if (summary.pendingSyncCount > 0)
            _SummaryCard(
              label: l10n.healthPendingSync,
              value: '${summary.pendingSyncCount}',
              icon: Icons.cloud_upload_outlined,
              color: theme.colorScheme.outline,
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.titleLarge),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
