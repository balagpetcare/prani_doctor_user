import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/navigation/navigation_guard.dart';
import '../../ai/presentation/ai_disclaimer_providers.dart';
import '../data/settings_dto.dart';
import '../data/settings_repository.dart';
import 'settings_navigation.dart';
import 'settings_providers.dart';
import 'widgets/settings_feedback.dart';

class AiConsentPage extends ConsumerWidget {
  const AiConsentPage({super.key});

  Future<void> _accept(
    BuildContext context,
    WidgetRef ref,
    LegalDocumentDto doc,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await ref
        .read(settingsRepositoryProvider)
        .sync(SettingsSyncInput(acceptAiVersion: doc.version));
    result.when(
      success: (_) {
        SettingsNavigation.afterLegalAccept(ref);
        ref.invalidate(aiDisclaimerProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsPrivacyAccepted)),
        );
        if (context.mounted) Navigator.of(context).maybePop();
      },
      failure: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final docAsync = ref.watch(aiConsentDocumentProvider);

    return Scaffold(
      appBar: safeAppBar(context, title: const Text('AI processing consent')),
      body: docAsync.when(
        loading: SettingsFeedback.loading,
        error: (e, _) => SettingsFeedback.error(
          context,
          error: e,
          onRetry: () => ref.invalidate(aiConsentDocumentProvider),
        ),
        data: (doc) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (doc.fromCache) SettingsFeedback.offlineHint(context),
              Text('${l10n.settingsVersionLabel}: ${doc.version}'),
              if (doc.accepted) ...[
                const SizedBox(height: 8),
                Chip(label: Text(l10n.settingsAccepted)),
              ],
              const SizedBox(height: 16),
              Text(doc.content),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: doc.url.isEmpty
                    ? null
                    : () => launchUrl(
                        Uri.parse(doc.url),
                        mode: LaunchMode.externalApplication,
                      ),
                icon: const Icon(Icons.open_in_new),
                label: Text(l10n.settingsOpenExternal),
              ),
              const SizedBox(height: 12),
              if (!doc.accepted)
                FilledButton(
                  onPressed: () => _accept(context, ref, doc),
                  child: Text(l10n.settingsAcceptPrivacy),
                ),
            ],
          );
        },
      ),
    );
  }
}
