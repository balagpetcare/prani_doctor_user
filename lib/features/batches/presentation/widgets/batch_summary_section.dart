import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

class BatchSummarySection extends StatelessWidget {
  const BatchSummarySection({
    super.key,
    required this.total,
    required this.withAnimalsCount,
    required this.pendingSyncCount,
  });

  final int total;
  final int withAnimalsCount;
  final int pendingSyncCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: l10n.batchSummaryTotal,
              value: '$total',
              icon: Icons.groups_outlined,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              label: l10n.batchSummaryWithAnimals,
              value: '$withAnimalsCount',
              icon: Icons.pets_outlined,
              color: theme.colorScheme.tertiary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              label: l10n.batchSummaryPendingSync,
              value: '$pendingSyncCount',
              icon: Icons.sync_problem_outlined,
              color: theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
