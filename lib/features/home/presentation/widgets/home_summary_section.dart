import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../home_providers.dart';

class HomeSummarySection extends StatelessWidget {
  const HomeSummarySection({super.key, required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.dashboardSummaryTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _SummaryCard(
              icon: Icons.agriculture_outlined,
              label: l10n.dashboardTotalFarms,
              value: '${summary.totalFarms}',
            ),
            _SummaryCard(
              icon: Icons.pets_outlined,
              label: l10n.dashboardTotalAnimals,
              value: '${summary.totalAnimals}',
            ),
            _SummaryCard(
              icon: Icons.event_available_outlined,
              label: l10n.dashboardAppointments,
              value: '${summary.activeAppointments}',
            ),
            _SummaryCard(
              icon: Icons.notifications_outlined,
              label: l10n.dashboardNotifications,
              value: '${summary.unreadNotifications}',
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 22, color: theme.colorScheme.primary),
            Text(value, style: theme.textTheme.headlineSmall),
            Text(label, style: theme.textTheme.bodySmall, maxLines: 2),
          ],
        ),
      ),
    );
  }
}
