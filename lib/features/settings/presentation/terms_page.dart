import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/navigation/navigation_guard.dart';

import 'package:url_launcher/url_launcher.dart';

import '../data/settings_dto.dart';
import '../data/settings_repository.dart';
import 'settings_providers.dart';
import 'settings_navigation.dart';
import 'widgets/settings_feedback.dart';

class TermsPage extends ConsumerWidget {
  const TermsPage({super.key});

  Future<void> _accept(
    BuildContext context,
    WidgetRef ref,
    LegalDocumentDto doc,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await ref
        .read(settingsRepositoryProvider)
        .sync(SettingsSyncInput(acceptTermsVersion: doc.version));
    result.when(
      success: (_) {
        ref.invalidate(termsDocumentProvider);
        ref.invalidate(settingsProvider);
        SettingsNavigation.afterLegalAccept(ref);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.settingsTermsAccepted)));
      },
      failure: (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final docAsync = ref.watch(termsDocumentProvider);

    return Scaffold(
      appBar: safeAppBar(context, title: Text(l10n.settingsTermsTitle)),
      body: docAsync.when(
        loading: SettingsFeedback.loading,
        error: (e, _) => SettingsFeedback.error(
          context,
          error: e,
          onRetry: () => ref.invalidate(termsDocumentProvider),
        ),
        data: (doc) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(termsDocumentProvider);
              await ref.read(termsDocumentProvider.future);
            },
            child: ListView(
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
                    child: Text(l10n.settingsAcceptTerms),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
