import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../routing/app_routes.dart';

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.dashboardQuickActionsTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ActionChip(
              icon: Icons.psychology_outlined,
              label: l10n.dashboardAskAi,
              onTap: () => context.push(AppRoutes.aiChat),
            ),
            _ActionChip(
              icon: Icons.add_home_work_outlined,
              label: l10n.dashboardCreateFarm,
              onTap: () => context.go(AppRoutes.farms),
            ),
            _ActionChip(
              icon: Icons.medical_services_outlined,
              label: l10n.dashboardRecordHealth,
              onTap: () => context.go(AppRoutes.healthHistory),
            ),
            _ActionChip(
              icon: Icons.account_balance_wallet_outlined,
              label: l10n.dashboardRecordFinance,
              onTap: () => context.go(AppRoutes.financeExpenses),
            ),
            _ActionChip(
              icon: Icons.grass_outlined,
              label: l10n.dashboardRecordFeed,
              onTap: () => context.go(AppRoutes.feeds),
            ),
            _ActionChip(
              icon: Icons.water_drop_outlined,
              label: l10n.dashboardRecordMilk,
              onTap: () => context.go(AppRoutes.milk),
            ),
            _ActionChip(
              icon: Icons.add_circle_outline,
              label: l10n.dashboardAddAnimal,
              onTap: () => context.go(AppRoutes.animalCreate),
            ),
            _ActionChip(
              icon: Icons.folder_open_outlined,
              label: l10n.dashboardViewRecords,
              onTap: () => context.go(AppRoutes.inbox),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
