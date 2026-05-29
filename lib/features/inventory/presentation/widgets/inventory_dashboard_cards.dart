import 'package:flutter/material.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../data/inventory_dto.dart';

class InventoryDashboardCards extends StatelessWidget {
  const InventoryDashboardCards({
    super.key,
    required this.summary,
    required this.onCurrentStock,
    required this.onLowStock,
    required this.onConsumptionHistory,
  });

  final InventorySummary summary;
  final VoidCallback onCurrentStock;
  final VoidCallback onLowStock;
  final VoidCallback onConsumptionHistory;

  @override
  Widget build(BuildContext context) {
    final l10n = context.tr;
    final theme = Theme.of(context);
    final itemCount =
        summary.feedActiveItems + summary.medicineActiveItems;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _DashboardCard(
                  icon: Icons.inventory_2_outlined,
                  label: l10n.t('inventoryCurrentStock'),
                  value: '$itemCount ${l10n.t('items')}',
                  onTap: onCurrentStock,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DashboardCard(
                  icon: Icons.warning_amber_outlined,
                  label: l10n.t('inventoryLowStock'),
                  value: '${summary.totalLowStock}',
                  highlight: summary.totalLowStock > 0,
                  onTap: onLowStock,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DashboardCard(
            icon: Icons.history,
            label: l10n.t('inventoryConsumptionHistoryMenu'),
            value: l10n.t('Feed & medicine usage'),
            fullWidth: true,
            onTap: onConsumptionHistory,
            subtitle: Text(
              l10n.t('View recent feeding logs'),
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.highlight = false,
    this.fullWidth = false,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool highlight;
  final bool fullWidth;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: highlight
          ? theme.colorScheme.errorContainer.withValues(alpha: 0.4)
          : theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: highlight ? theme.colorScheme.error : null),
              const SizedBox(height: 8),
              Text(label, style: theme.textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(value, style: theme.textTheme.titleMedium),
              if (subtitle != null) ...[const SizedBox(height: 4), subtitle!],
            ],
          ),
        ),
      ),
    );
  }
}
