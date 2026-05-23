import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../data/vaccine_dto.dart';

class VaccineSummarySection extends StatelessWidget {
  const VaccineSummarySection({super.key, required this.summary});

  final VaccineSummaryData summary;

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
            label: l10n.vaccineSummaryCompleted,
            value: '${summary.completed}',
            icon: Icons.check_circle_outline,
            color: theme.colorScheme.primary,
          ),
          _SummaryCard(
            label: l10n.vaccineSummaryUpcoming,
            value: '${summary.upcoming}',
            icon: Icons.event_outlined,
            color: theme.colorScheme.tertiary,
          ),
          _SummaryCard(
            label: l10n.vaccineSummaryOverdue,
            value: '${summary.overdue}',
            icon: Icons.warning_amber_outlined,
            color: theme.colorScheme.error,
          ),
          if (summary.pendingSyncCount > 0)
            _SummaryCard(
              label: l10n.vaccinePendingSync,
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
