import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../routing/app_routes.dart';
import '../../../doctors/data/doctor_repository.dart';
import '../theme/home_tokens.dart';
import 'instant_care_sheet.dart';

class HomeCareActionBar extends ConsumerWidget {
  const HomeCareActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final actions = [
      _CareAction(
        icon: Icons.smart_toy_outlined,
        label: l10n.homeActionAiDoctor,
        onTap: () => context.push(AppRoutes.aiChat),
      ),
      _CareAction(
        icon: Icons.medical_services_outlined,
        label: l10n.homeActionCallDoctor,
        onTap: () => context.go(AppRoutes.services),
      ),
      _CareAction(
        icon: Icons.engineering_outlined,
        label: l10n.homeActionAiTechnician,
        onTap: () => context.push(AppRoutes.aiChat),
      ),
      _CareAction(
        icon: Icons.emergency_outlined,
        label: l10n.filterEmergency,
        onTap: () => showInstantCareSheet(context, ref),
        accent: theme.colorScheme.error,
      ),
      _CareAction(
        icon: Icons.videocam_outlined,
        label: l10n.homeActionVideoCall,
        onTap: () {
          ref.read(doctorDiscoveryFiltersProvider.notifier).state =
              const DoctorDiscoveryFilters(onlineOnly: true);
          ref.invalidate(doctorListProvider);
          context.go(AppRoutes.services);
        },
      ),
      _CareAction(
        icon: Icons.support_agent_outlined,
        label: l10n.dashboardSupportTitle,
        onTap: () => context.push(AppRoutes.support),
      ),
    ];

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          HomeTokens.space16,
          HomeTokens.space12,
          HomeTokens.space16,
          0,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final chipHeight = (72 * textScale).clamp(72.0, 120.0);
            return SizedBox(
              height: chipHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: actions.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: HomeTokens.space8),
                itemBuilder: (context, index) {
                  return _CareActionChip(
                    action: actions[index],
                    minHeight: chipHeight,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CareAction {
  const _CareAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? accent;
}

class _CareActionChip extends StatelessWidget {
  const _CareActionChip({required this.action, required this.minHeight});

  final _CareAction action;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = action.accent ?? theme.colorScheme.primary;

    return Semantics(
      button: true,
      label: action.label,
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(HomeTokens.radiusMd),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: action.onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight, minWidth: 92),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: HomeTokens.space8,
                vertical: HomeTokens.space8,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(action.icon, color: color, size: 24),
                  const SizedBox(height: HomeTokens.space4),
                  Flexible(
                    child: Text(
                      action.label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
