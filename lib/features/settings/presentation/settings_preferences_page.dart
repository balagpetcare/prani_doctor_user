import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/navigation/navigation_guard.dart';

import '../../../routing/app_routes.dart';
import '../../../theme/theme_controller.dart';
import '../data/settings_dto.dart';
import 'settings_providers.dart';
import 'widgets/settings_section_header.dart';

class SettingsPreferencesPage extends ConsumerWidget {
  const SettingsPreferencesPage({super.key});

  static String _localeLabel(AppLocalizations l10n, String? locale) {
    if (locale == 'en-US') return l10n.languageEnglish;
    return l10n.languageBangla;
  }

  static String _themeLabel(AppLocalizations l10n, SettingsTheme theme) {
    return switch (theme) {
      SettingsTheme.light => l10n.settingsThemeLight,
      SettingsTheme.dark => l10n.settingsThemeDark,
      SettingsTheme.system => l10n.settingsThemeSystem,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider).valueOrNull;
    final mode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: safeAppBar(context, title: Text(l10n.settingsPreferencesTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.settingsPreferencesSubtitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SettingsSectionHeader(title: l10n.settingsPreferencesSection),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.languageTitle),
            subtitle: Text(_localeLabel(l10n, settings?.settings.locale)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.settingsLanguage),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(l10n.settingsThemeTitle),
            subtitle: Text(
              _themeLabel(
                l10n,
                settings?.settings.theme ?? themeModeToSettings(mode),
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.settingsTheme),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: Text(l10n.notificationSettingsTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.settingsNotifications),
          ),
        ],
      ),
    );
  }
}
