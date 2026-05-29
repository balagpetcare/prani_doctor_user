import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/navigation/navigation_guard.dart';
import '../../../routing/app_routes.dart';
import '../data/settings_dto.dart';
import '../data/settings_repository.dart';
import 'settings_navigation.dart';
import 'settings_providers.dart';
import 'widgets/settings_feedback.dart';

/// Hard gate when privacy or terms versions are stale — onboarding is unchanged.
class ReConsentPage extends ConsumerStatefulWidget {
  const ReConsentPage({super.key});

  @override
  ConsumerState<ReConsentPage> createState() => _ReConsentPageState();
}

class _ReConsentPageState extends ConsumerState<ReConsentPage> {
  bool _accepting = false;

  Future<void> _acceptAll(LegalDocumentDto privacy, LegalDocumentDto terms) async {
    if (_accepting) return;
    setState(() => _accepting = true);
    final l10n = AppLocalizations.of(context)!;
    final result = await ref.read(settingsRepositoryProvider).sync(
          SettingsSyncInput(
            acceptPrivacyVersion: privacy.version,
            acceptTermsVersion: terms.version,
          ),
        );
    if (!mounted) return;
    setState(() => _accepting = false);
    result.when(
      success: (_) {
        SettingsNavigation.afterLegalAccept(ref);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.reconsentAccepted)),
        );
        context.go(AppRoutes.home);
      },
      failure: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final privacyAsync = ref.watch(privacyDocumentProvider);
    final termsAsync = ref.watch(termsDocumentProvider);
    final settings = ref.watch(settingsProvider).valueOrNull?.legal;

    return Scaffold(
      appBar: safeAppBar(context, title: Text(l10n.reconsentTitle)),
      body: privacyAsync.when(
        loading: SettingsFeedback.loading,
        error: (e, _) => SettingsFeedback.error(
          context,
          error: e,
          onRetry: () {
            ref.invalidate(privacyDocumentProvider);
            ref.invalidate(termsDocumentProvider);
          },
        ),
        data: (privacy) => termsAsync.when(
          loading: SettingsFeedback.loading,
          error: (e, _) => SettingsFeedback.error(
            context,
            error: e,
            onRetry: () => ref.invalidate(termsDocumentProvider),
          ),
          data: (terms) {
            final allAccepted =
                settings?.privacyAccepted == true && settings?.termsAccepted == true;
            if (allAccepted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) context.go(AppRoutes.home);
              });
            }

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(l10n.reconsentBody, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 24),
                _DocSection(
                  title: l10n.privacyPolicy,
                  version: privacy.version,
                  content: privacy.content,
                  url: privacy.url,
                ),
                const SizedBox(height: 16),
                _DocSection(
                  title: l10n.settingsTermsTitle,
                  version: terms.version,
                  content: terms.content,
                  url: terms.url,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _accepting ? null : () => _acceptAll(privacy, terms),
                  child: _accepting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.reconsentAcceptContinue),
                ),
                TextButton(
                  onPressed: () => context.push(AppRoutes.settingsPrivacy),
                  child: Text(l10n.reconsentReadPrivacy),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DocSection extends StatelessWidget {
  const _DocSection({
    required this.title,
    required this.version,
    required this.content,
    required this.url,
  });

  final String title;
  final String version;
  final String content;
  final String url;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('${l10n.settingsVersionLabel}: $version'),
            const SizedBox(height: 8),
            Text(content, maxLines: 6, overflow: TextOverflow.ellipsis),
            if (url.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(l10n.settingsOpenExternal),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
