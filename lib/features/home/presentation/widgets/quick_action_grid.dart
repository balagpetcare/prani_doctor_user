import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../routing/app_routes.dart';
import '../../data/dashboard_context_dto.dart';
import '../models/home_section_models.dart';
import '../theme/home_tokens.dart';
import 'home_card.dart';
import 'home_layout.dart';

class HomeQuickActionGrid extends StatelessWidget {
  const HomeQuickActionGrid({super.key, required this.dashboardType});

  final DashboardType dashboardType;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isTechnician = dashboardType == DashboardType.aiTechnician;
    final actions = isTechnician
        ? _technicianActions(l10n)
        : _customerActions(l10n);
    final columns = HomeTokens.quickActionColumns(context);

    return SliverToBoxAdapter(
      child: HomeSectionScope(
        label: l10n.dashboardQuickActionsTitle,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            HomeTokens.space16,
            HomeTokens.space20,
            HomeTokens.space16,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeSectionHeader(title: l10n.dashboardQuickActionsTitle),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: HomeTokens.space8,
                  crossAxisSpacing: HomeTokens.space8,
                  childAspectRatio: columns > 4 ? 0.9 : 0.82,
                ),
                itemCount: actions.length,
                itemBuilder: (context, index) {
                  final action = actions[index];
                  return _QuickActionTile(
                    action: action,
                    onTap: () {
                      if (action.isEmergency) {
                        context.go(AppRoutes.services);
                        return;
                      }
                      if (action.route == AppRoutes.inbox ||
                          action.route == AppRoutes.services) {
                        context.go(action.route);
                      } else {
                        context.push(action.route);
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<HomeQuickActionItem> _customerActions(AppLocalizations l10n) => [
    HomeQuickActionItem(
      icon: Icons.add_circle_outline,
      label: l10n.dashboardAddAnimal,
      route: AppRoutes.animalCreate,
    ),
    HomeQuickActionItem(
      icon: Icons.calendar_month_outlined,
      label: l10n.homeBookDoctor,
      route: AppRoutes.services,
    ),
    HomeQuickActionItem(
      icon: Icons.medical_services_outlined,
      label: l10n.treatmentListTitle,
      route: AppRoutes.treatments,
    ),
    HomeQuickActionItem(
      icon: Icons.vaccines_outlined,
      label: l10n.vaccineDashboardTitle,
      route: AppRoutes.vaccines,
    ),
    HomeQuickActionItem(
      icon: Icons.place_outlined,
      label: l10n.homeNearbyServices,
      route: AppRoutes.services,
    ),
    HomeQuickActionItem(
      icon: Icons.upload_file_outlined,
      label: l10n.homeUploadReport,
      route: AppRoutes.healthCreate,
    ),
    HomeQuickActionItem(
      icon: Icons.history_outlined,
      label: l10n.homeHealthHistoryAction,
      route: AppRoutes.healthHistory,
    ),
  ];

  List<HomeQuickActionItem> _technicianActions(AppLocalizations l10n) => [
    HomeQuickActionItem(
      icon: Icons.inbox_outlined,
      label: l10n.dashboardViewRecords,
      route: AppRoutes.inbox,
    ),
    HomeQuickActionItem(
      icon: Icons.medical_services_outlined,
      label: l10n.navServices,
      route: AppRoutes.services,
    ),
    HomeQuickActionItem(
      icon: Icons.support_agent_outlined,
      label: l10n.dashboardSupportTitle,
      route: AppRoutes.support,
    ),
  ];
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action, required this.onTap});

  final HomeQuickActionItem action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: action.label,
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(HomeTokens.radiusMd),
        clipBehavior: Clip.antiAlias,
        elevation: HomeTokens.elevationNone,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(HomeTokens.space8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  action.icon,
                  color: action.isEmergency
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
                const SizedBox(height: HomeTokens.space8 - 2),
                Text(
                  action.label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
