import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../data/ai_dto.dart';
import 'ai_navigation.dart';
import 'ai_providers.dart';
import 'compliance/ai_compliance_model.dart';
import 'compliance/ai_compliance_shell.dart';

class AiSettingsPage extends ConsumerStatefulWidget {
  const AiSettingsPage({super.key});

  @override
  ConsumerState<AiSettingsPage> createState() => _AiSettingsPageState();
}

class _AiSettingsPageState extends ConsumerState<AiSettingsPage> {
  AiSettings? _draft;

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null) return;
    await ref.read(aiSettingsProvider.notifier).save(draft);
    AiNavigation.afterSettingsSave(ref);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.aiSettingsSaved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settingsAsync = ref.watch(aiSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aiSettingsTitle)),
      body: AiCompliancePageBody(
        surface: AiComplianceSurface.chat,
        child: settingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (settings) {
            _draft ??= settings;
            final draft = _draft!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  l10n.aiSettingsLanguage,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                RadioListTile<AiLocale>(
                  title: Text(l10n.aiLocaleBn),
                  value: AiLocale.bn,
                  groupValue: draft.locale,
                  onChanged: (v) =>
                      setState(() => _draft = draft.copyWith(locale: v)),
                ),
                RadioListTile<AiLocale>(
                  title: Text(l10n.aiLocaleEn),
                  value: AiLocale.en,
                  groupValue: draft.locale,
                  onChanged: (v) =>
                      setState(() => _draft = draft.copyWith(locale: v)),
                ),
                SwitchListTile(
                  title: Text(l10n.aiSettingsSuggestions),
                  value: draft.showSuggestions,
                  onChanged: (v) =>
                      setState(() => _draft = draft.copyWith(showSuggestions: v)),
                ),
                SwitchListTile(
                  title: Text(l10n.aiSettingsMemory),
                  subtitle: Text(l10n.aiSettingsMemoryHint),
                  value: draft.rememberConversations,
                  onChanged: (v) => setState(
                    () => _draft = draft.copyWith(rememberConversations: v),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(onPressed: _save, child: Text(l10n.aiSaveSettings)),
              ],
            );
          },
        ),
      ),
    );
  }
}
