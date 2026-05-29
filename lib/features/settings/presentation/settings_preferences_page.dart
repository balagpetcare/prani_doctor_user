import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/localization/language_controller.dart';
import '../../../core/localization/locale_storage.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/navigation/navigation_guard.dart';
import '../../../routing/app_routes.dart';
import '../../../theme/theme_controller.dart';
import '../../profile/data/mobile_me_dto.dart';
import '../../profile/presentation/profile_providers.dart';
import '../data/settings_dto.dart';
import 'settings_providers.dart';
import 'widgets/settings_section_header.dart';

class SettingsPreferencesPage extends ConsumerStatefulWidget {
  const SettingsPreferencesPage({super.key});

  @override
  ConsumerState<SettingsPreferencesPage> createState() =>
      _SettingsPreferencesPageState();
}

class _SettingsPreferencesPageState
    extends ConsumerState<SettingsPreferencesPage> {
  bool _languageSaving = false;

  Future<void> _setLanguage(String languageCode) async {
    if (_languageSaving) return;
    setState(() => _languageSaving = true);

    final apiTag = LocaleStorage.toApiTag(languageCode);
    await ref.read(languageControllerProvider.notifier).setLanguageCode(
          languageCode,
        );

    unawaited(
      ref.read(settingsProvider.notifier).syncLocale(apiTag),
    );
    unawaited(
      ref.read(mobileMeProvider.notifier).save(PatchMobileMeInput(locale: apiTag)),
    );

    if (mounted) {
      setState(() => _languageSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.settingsLanguageSaved)),
      );
    }
  }

  static String _themeLabel(AppLocalizations l10n, SettingsTheme theme) {
    return switch (theme) {
      SettingsTheme.light => l10n.settingsThemeLight,
      SettingsTheme.dark => l10n.settingsThemeDark,
      SettingsTheme.system => l10n.settingsThemeSystem,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.tr;
    final settings = ref.watch(settingsProvider).valueOrNull;
    final mode = ref.watch(themeModeProvider);
    final activeLocale = ref.watch(languageControllerProvider).languageCode;

    return Scaffold(
      appBar: safeAppBar(context, title: Text(l10n.settingsPreferencesTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.settingsPreferencesSubtitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SettingsSectionHeader(title: l10n.languageTitle),
          RadioListTile<String>(
            title: Text(l10n.languageBangla),
            value: 'bn',
            groupValue: activeLocale,
            onChanged: _languageSaving
                ? null
                : (value) {
                    if (value != null) _setLanguage(value);
                  },
          ),
          RadioListTile<String>(
            title: Text(l10n.languageEnglish),
            value: 'en',
            groupValue: activeLocale,
            onChanged: _languageSaving
                ? null
                : (value) {
                    if (value != null) _setLanguage(value);
                  },
          ),
          if (_languageSaving)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: CircularProgressIndicator()),
            ),
          SettingsSectionHeader(title: l10n.settingsPreferencesSection),
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
