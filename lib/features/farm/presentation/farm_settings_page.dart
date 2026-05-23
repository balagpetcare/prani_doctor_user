import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/navigation/navigation_guard.dart';

import '../../../routing/app_routes.dart';
import 'farm_navigation.dart';
import 'farm_providers.dart';

class FarmSettingsPage extends ConsumerWidget {
  const FarmSettingsPage({super.key, required this.farmId});

  final String farmId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final activeId = ref.watch(activeFarmIdProvider).valueOrNull;

    return Scaffold(
      appBar: safeAppBar(context, title: Text(l10n.farmSettingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(l10n.farmEditTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.farmEdit(farmId)),
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: Text(l10n.farmRefreshData),
            onTap: () {
              FarmNavigation.refreshFarmDetail(ref, farmId);
              FarmNavigation.refreshFarmList(ref);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.farmRefreshStarted)));
            },
          ),
          if (activeId == farmId)
            ListTile(
              leading: Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(l10n.farmActiveFarm),
              subtitle: Text(l10n.farmActiveFarmHint),
            )
          else
            ListTile(
              leading: const Icon(Icons.home_work_outlined),
              title: Text(l10n.farmSetActive),
              onTap: () => FarmNavigation.setActiveFarm(ref, farmId),
            ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.farmSingleFarmNotice,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
