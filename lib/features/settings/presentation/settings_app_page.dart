import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/navigation/navigation_guard.dart';

import '../../../routing/app_routes.dart';
import 'widgets/settings_section_header.dart';

class SettingsAppPage extends StatelessWidget {
  const SettingsAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: safeAppBar(context, title: Text(l10n.settingsAppTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.settingsAppSubtitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SettingsSectionHeader(title: l10n.settingsAppSection),
          ListTile(
            leading: const Icon(Icons.tune),
            title: Text(l10n.settingsPreferencesTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.settingsPreferences),
          ),
          ListTile(
            leading: const Icon(Icons.network_check),
            title: Text(l10n.networkConnectionTitle),
            subtitle: Text(l10n.networkConnectionSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.settingsConnection),
          ),
          ListTile(
            leading: const Icon(Icons.sync),
            title: Text(l10n.settingsDataSyncTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.settingsDataSync),
          ),
          ListTile(
            leading: const Icon(Icons.smart_toy_outlined),
            title: Text(l10n.aiSettingsTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.aiSettings),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.settingsAboutTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.settingsAbout),
          ),
        ],
      ),
    );
  }
}
