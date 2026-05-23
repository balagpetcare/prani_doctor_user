import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/navigation/navigation_guard.dart';

import '../../profile/data/mobile_me_dto.dart';
import '../../profile/presentation/profile_providers.dart';
import 'settings_navigation.dart';
import 'settings_providers.dart';
import 'widgets/settings_feedback.dart';

class SettingsLanguagePage extends ConsumerStatefulWidget {
  const SettingsLanguagePage({super.key});

  @override
  ConsumerState<SettingsLanguagePage> createState() =>
      _SettingsLanguagePageState();
}

class _SettingsLanguagePageState extends ConsumerState<SettingsLanguagePage> {
  String? _selected;
  bool _loading = false;
  String? _error;

  Future<void> _save(String locale) async {
    if (ref.read(settingsUpdateInFlightProvider)) return;
    setState(() {
      _loading = true;
      _error = null;
      _selected = locale;
    });

    final settingsResult = await ref
        .read(settingsProvider.notifier)
        .syncLocale(locale);
    final profileError = await ref
        .read(mobileMeProvider.notifier)
        .save(PatchMobileMeInput(locale: locale));

    if (!mounted) return;
    setState(() => _loading = false);

    settingsResult.when(
      success: (_) => SettingsNavigation.afterSync(ref),
      failure: (e) {
        if (!e.message.contains('offline')) {
          setState(() => _error = e.message);
        }
      },
    );

    if (profileError != null && !profileError.contains('offline')) {
      setState(() => _error = profileError);
      return;
    }

    if (_error == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.settingsLanguageSaved)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settingsAsync = ref.watch(settingsProvider);
    final profileAsync = ref.watch(mobileMeProvider);
    final current =
        _selected ??
        settingsAsync.valueOrNull?.settings.locale ??
        profileAsync.value?.locale ??
        'bn-BD';

    return Scaffold(
      appBar: safeAppBar(context, title: Text(l10n.languageTitle)),
      body: settingsAsync.when(
        loading: SettingsFeedback.loading,
        error: (e, _) => SettingsFeedback.error(
          context,
          error: e,
          onRetry: () => ref.read(settingsProvider.notifier).refresh(),
        ),
        data: (_) {
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
              RadioListTile<String>(
                title: Text(l10n.languageBangla),
                value: 'bn-BD',
                groupValue: current,
                onChanged: _loading ? null : (value) => _save(value!),
              ),
              RadioListTile<String>(
                title: Text(l10n.languageEnglish),
                value: 'en-US',
                groupValue: current,
                onChanged: _loading ? null : (value) => _save(value!),
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
