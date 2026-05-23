import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/layout/shell_page_padding.dart';
import '../../../routing/app_routes.dart';
import '../auth/presentation/auth_logout.dart';
import '../profile/presentation/profile_providers.dart';
import 'presentation/settings_providers.dart';
import 'presentation/widgets/settings_feedback.dart';
import 'presentation/widgets/settings_section_header.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(mobileMeProvider);
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: Text(l10n.navSettings),
          automaticallyImplyLeading: false,
        ),
        body: SettingsFeedback.loading(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          title: Text(l10n.navSettings),
          automaticallyImplyLeading: false,
        ),
        body: SettingsFeedback.error(
          context,
          error: e,
          onRetry: () => ref.read(settingsProvider.notifier).refresh(),
        ),
      ),
      data: (settingsBundle) {
        return RefreshIndicator(
          onRefresh: () => ref.read(settingsProvider.notifier).refresh(),
          child: ListView(
            padding: ShellPagePadding.page(context),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Text(
                l10n.navSettings,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (settingsBundle?.fromCache == true) ...[
                const SizedBox(height: 8),
                SettingsFeedback.offlineHint(context),
              ],
              const SizedBox(height: 8),
              profileAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => Text(l10n.profileLoadError),
                data: (profile) {
                  if (profile == null) return Text(l10n.profileLoadError);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      child: Text(
                        profile.name.isNotEmpty ? profile.name[0] : '?',
                      ),
                    ),
                    title: Text(profile.name),
                    subtitle: Text(profile.phone),
                  );
                },
              ),
              SettingsSectionHeader(title: l10n.settingsHubAccountSection),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(l10n.settingsAccountTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.settingsAccount),
              ),
              SettingsSectionHeader(title: l10n.settingsHubAppSection),
              ListTile(
                leading: const Icon(Icons.tune),
                title: Text(l10n.settingsPreferencesTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.settingsPreferences),
              ),
              ListTile(
                leading: const Icon(Icons.settings_applications_outlined),
                title: Text(l10n.settingsAppTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.settingsApp),
              ),
              SettingsSectionHeader(title: l10n.settingsHubLegalSection),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(l10n.privacyPolicy),
                subtitle: Text(
                  settingsBundle?.legal.privacyAccepted == true
                      ? l10n.settingsAccepted
                      : l10n.privacyPolicySubtitle,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.settingsPrivacy),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(l10n.settingsTermsTitle),
                subtitle: Text(
                  settingsBundle?.legal.termsAccepted == true
                      ? l10n.settingsAccepted
                      : l10n.settingsTermsSubtitle,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.settingsTerms),
              ),
              SettingsSectionHeader(title: l10n.settingsHubSupportSection),
              ListTile(
                leading: const Icon(Icons.support_agent_outlined),
                title: Text(l10n.supportHelpTitle),
                subtitle: Text(l10n.supportHelpSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(AppRoutes.support),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.settingsAboutTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.settingsAbout),
              ),
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: () => performAuthLogout(ref),
                child: Text(l10n.signOut),
              ),
            ],
          ),
        );
      },
    );
  }
}
