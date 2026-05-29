import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/navigation/navigation_guard.dart';

import 'package:url_launcher/url_launcher.dart';
import '../../consent/data/consent_repository.dart';
import '../data/settings_dto.dart';
import '../data/settings_repository.dart';
import 'settings_providers.dart';
import 'settings_navigation.dart';
import 'widgets/settings_feedback.dart';

class PrivacyPage extends ConsumerWidget {
  const PrivacyPage({super.key});

  Future<void> _accept(
    BuildContext context,
    WidgetRef ref,
    LegalDocumentDto doc,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await ref
        .read(settingsRepositoryProvider)
        .sync(SettingsSyncInput(acceptPrivacyVersion: doc.version));
    result.when(
      success: (_) {
        ref.invalidate(privacyDocumentProvider);
        ref.invalidate(settingsProvider);
        SettingsNavigation.afterLegalAccept(ref);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.settingsPrivacyAccepted)));
      },
      failure: (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      },
    );
  }

  Future<void> _withdraw(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.consentWithdrawPrivacy),
        content: Text(l10n.consentWithdrawConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.consentWithdrawPrivacy),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(consentRepositoryProvider)
        .withdraw(consentType: 'PRIVACY');
    if (!context.mounted) return;
    result.when(
      success: (_) {
        ref.invalidate(privacyDocumentProvider);
        ref.invalidate(settingsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.consentWithdrawn)),
        );
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
    final docAsync = ref.watch(privacyDocumentProvider);

    return Scaffold(
      appBar: safeAppBar(context, title: Text(l10n.privacyPolicy)),
      body: docAsync.when(
        loading: SettingsFeedback.loading,
        error: (e, _) => SettingsFeedback.error(
          context,
          error: e,
          onRetry: () => ref.invalidate(privacyDocumentProvider),
        ),
        data: (doc) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(privacyDocumentProvider);
              await ref.read(privacyDocumentProvider.future);
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
                    child: Text(l10n.settingsAcceptPrivacy),
                  ),
                if (doc.accepted) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => _withdraw(context, ref),
                    child: Text(l10n.consentWithdrawPrivacy),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
