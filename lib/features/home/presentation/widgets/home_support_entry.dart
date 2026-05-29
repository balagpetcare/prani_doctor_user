import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../routing/app_routes.dart';
import '../../../app_config/presentation/app_config_provider.dart';
import '../../data/dashboard_context_dto.dart';

class HomeSupportEntry extends ConsumerWidget {
  const HomeSupportEntry({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final config = ref.watch(appConfigProvider);
    final hasContacts = config?.hasSupportContacts ?? false;

    if (!hasContacts) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.help_outline),
          title: Text(l10n.dashboardSupportTitle),
          subtitle: Text(l10n.dashboardSupportHelpSubtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppRoutes.support),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.support_agent_outlined),
            title: Text(l10n.dashboardSupportTitle),
            subtitle: Text(l10n.dashboardSupportSubtitle),
          ),
          if (config?.supportPhone?.isNotEmpty ?? false)
            ListTile(
              dense: true,
              leading: const Icon(Icons.phone_outlined, size: 20),
              title: Text(config!.supportPhone!),
              onTap: () => _launchTel(config.supportPhone!),
            ),
          if (config?.emergencyPhone?.isNotEmpty ?? false)
            ListTile(
              dense: true,
              leading: const Icon(Icons.emergency_outlined, size: 20),
              title: Text(
                l10n.dashboardEmergencyPhone(config!.emergencyPhone!),
              ),
              onTap: () => _launchTel(config.emergencyPhone!),
            ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.confirmation_number_outlined, size: 20),
            title: Text(l10n.dashboardSupportTickets),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => context.push(AppRoutes.support),
          ),
        ],
      ),
    );
  }

  Future<void> _launchTel(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class HomeAiTechnicianSection extends StatelessWidget {
  const HomeAiTechnicianSection({super.key, required this.contextData});

  final DashboardContext contextData;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tech = contextData.aiTechnician;
    if (tech == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.dashboardAiTechnicianTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _StatRow(
              label: l10n.dashboardAiTodayRequests,
              value: '${tech.todayRequestCount}',
            ),
            _StatRow(
              label: l10n.dashboardAiPendingRequests,
              value: '${tech.pendingRequestCount}',
            ),
            _StatRow(
              label: l10n.dashboardAiCompletedServices,
              value: '${tech.completedServiceCount}',
            ),
            if (tech.rating.count > 0)
              _StatRow(
                label: l10n.dashboardAiRating,
                value:
                    '${tech.rating.average?.toStringAsFixed(1) ?? '—'} (${tech.rating.count})',
              ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleSmall,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
