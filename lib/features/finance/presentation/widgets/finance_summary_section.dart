import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

class FinanceSummarySection extends StatelessWidget {
  const FinanceSummarySection({
    super.key,
    required this.incomeBdt,
    required this.expenseBdt,
    required this.profitBdt,
  });

  final double incomeBdt;
  final double expenseBdt;
  final double profitBdt;

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
              label: l10n.financeTotalIncome,
              value: l10n.financeAmountValue(incomeBdt),
              icon: Icons.arrow_downward,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              label: l10n.financeTotalExpense,
              value: l10n.financeAmountValue(expenseBdt),
              icon: Icons.arrow_upward,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              label: l10n.financeProfitSummary,
              value: l10n.financeAmountValue(profitBdt),
              icon: Icons.account_balance_wallet_outlined,
              color: theme.colorScheme.tertiary,
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
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
