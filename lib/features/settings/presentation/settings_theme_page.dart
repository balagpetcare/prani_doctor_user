import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/navigation/navigation_guard.dart';

import '../../../theme/theme_controller.dart';
import '../data/settings_dto.dart';
import 'settings_navigation.dart';
import 'settings_providers.dart';
import 'widgets/settings_feedback.dart';

class SettingsThemePage extends ConsumerStatefulWidget {
  const SettingsThemePage({super.key});

  @override
  ConsumerState<SettingsThemePage> createState() => _SettingsThemePageState();
}

class _SettingsThemePageState extends ConsumerState<SettingsThemePage> {
  SettingsTheme? _pending;
  bool _loading = false;
  String? _error;

  Future<void> _select(SettingsTheme theme) async {
    if (ref.read(settingsUpdateInFlightProvider)) return;
    setState(() {
      _pending = theme;
      _loading = true;
      _error = null;
    });

    ref.read(themeModeProvider.notifier).state = settingsThemeToMode(theme);
    final result = await ref.read(settingsProvider.notifier).syncTheme(theme);

    if (!mounted) return;
    setState(() => _loading = false);

    result.when(
      success: (_) {
        SettingsNavigation.afterSync(ref);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.settingsThemeSaved),
          ),
        );
      },
      failure: (e) {
        if (e.message.contains('offline')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.savedOffline)),
          );
          return;
        }
        setState(() => _error = e.message);
      },
    );
  }

  String _label(AppLocalizations l10n, SettingsTheme theme) => switch (theme) {
    SettingsTheme.light => l10n.settingsThemeLight,
    SettingsTheme.dark => l10n.settingsThemeDark,
    SettingsTheme.system => l10n.settingsThemeSystem,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settingsAsync = ref.watch(settingsProvider);
    final mode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: safeAppBar(context, title: Text(l10n.settingsThemeTitle)),
      body: settingsAsync.when(
        loading: SettingsFeedback.loading,
        error: (e, _) => SettingsFeedback.error(
          context,
          error: e,
          onRetry: () => ref.read(settingsProvider.notifier).refresh(),
        ),
        data: (bundle) {
          final current =
              _pending ?? bundle?.settings.theme ?? themeModeToSettings(mode);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              for (final theme in SettingsTheme.values)
                RadioListTile<SettingsTheme>(
                  title: Text(_label(l10n, theme)),
                  value: theme,
                  groupValue: current,
                  onChanged: _loading ? null : (value) => _select(value!),
                ),
              if (_loading) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          );
        },
      ),
    );
  }
}
