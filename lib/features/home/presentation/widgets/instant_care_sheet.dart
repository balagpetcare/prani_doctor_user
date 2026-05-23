import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../routing/app_routes.dart';
import '../../../app_config/presentation/app_config_provider.dart';
import '../../../doctors/data/doctor_repository.dart';
import '../theme/home_tokens.dart';

enum InstantCareAction {
  aiDoctor,
  callDoctor,
  emergencyVisit,
  videoConsultation,
  nearestService,
  chat,
}

Future<void> showInstantCareSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => SafeArea(child: _InstantCareSheet(parentRef: ref)),
  );
}

class _InstantCareSheet extends ConsumerWidget {
  const _InstantCareSheet({required this.parentRef});

  final WidgetRef parentRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final items = <_CareItem>[
      _CareItem(
        icon: Icons.smart_toy_outlined,
        title: l10n.homeCareAiDoctor,
        subtitle: l10n.homeCareAiDoctorEta,
        action: InstantCareAction.aiDoctor,
      ),
      _CareItem(
        icon: Icons.phone_in_talk_outlined,
        title: l10n.homeCareCallDoctor,
        subtitle: l10n.homeCareCallDoctorEta,
        action: InstantCareAction.callDoctor,
      ),
      _CareItem(
        icon: Icons.emergency_outlined,
        title: l10n.homeCareEmergencyVisit,
        subtitle: l10n.homeCareEmergencyVisitEta,
        action: InstantCareAction.emergencyVisit,
        accent: theme.colorScheme.error,
      ),
      _CareItem(
        icon: Icons.videocam_outlined,
        title: l10n.homeCareVideoConsultation,
        subtitle: l10n.homeCareVideoConsultationEta,
        action: InstantCareAction.videoConsultation,
      ),
      _CareItem(
        icon: Icons.place_outlined,
        title: l10n.homeCareNearestService,
        subtitle: l10n.homeCareNearestServiceEta,
        action: InstantCareAction.nearestService,
      ),
      _CareItem(
        icon: Icons.chat_bubble_outline,
        title: l10n.homeCareChat,
        subtitle: l10n.homeCareChatEta,
        action: InstantCareAction.chat,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HomeTokens.space16,
        0,
        HomeTokens.space16,
        HomeTokens.space16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.homeInstantCareTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: HomeTokens.space4),
          Text(l10n.homeInstantCareSubtitle, style: theme.textTheme.bodySmall),
          const SizedBox(height: HomeTokens.space12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: HomeTokens.space8),
              child: _CareTile(
                item: item,
                onTap: () => _handleAction(context, parentRef, item.action),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    InstantCareAction action,
  ) async {
    Navigator.of(context).pop();
    switch (action) {
      case InstantCareAction.aiDoctor:
        if (context.mounted) context.push(AppRoutes.aiChat);
      case InstantCareAction.callDoctor:
      case InstantCareAction.emergencyVisit:
        await _openEmergencyServices(context, ref);
      case InstantCareAction.videoConsultation:
        ref.read(doctorDiscoveryFiltersProvider.notifier).state =
            const DoctorDiscoveryFilters(onlineOnly: true);
        ref.invalidate(doctorListProvider);
        if (context.mounted) context.go(AppRoutes.services);
      case InstantCareAction.nearestService:
        if (context.mounted) context.go(AppRoutes.services);
      case InstantCareAction.chat:
        if (context.mounted) context.push(AppRoutes.support);
    }
  }

  Future<void> _openEmergencyServices(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final config = ref.read(appConfigProvider);
    final phone = config?.emergencyPhone;
    if (phone != null && phone.isNotEmpty) {
      final uri = Uri(scheme: 'tel', path: phone);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
    ref.read(doctorDiscoveryFiltersProvider.notifier).state =
        const DoctorDiscoveryFilters(emergencyOnly: true);
    ref.invalidate(doctorListProvider);
    if (context.mounted) context.go(AppRoutes.services);
  }
}

class _CareItem {
  const _CareItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
    this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final InstantCareAction action;
  final Color? accent;
}

class _CareTile extends StatelessWidget {
  const _CareTile({required this.item, required this.onTap});

  final _CareItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = item.accent ?? theme.colorScheme.primary;

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(HomeTokens.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(HomeTokens.space12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(item.icon, color: color, size: 22),
              ),
              const SizedBox(width: HomeTokens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item.subtitle,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
