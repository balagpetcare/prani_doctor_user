import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import '../../../theme/theme_controller.dart';
import '../auth/data/auth_repository.dart';
import 'data/settings_dto.dart';
import '../offline/presentation/offline_queue_panel.dart';
import '../profile/presentation/profile_providers.dart';
import 'presentation/settings_providers.dart';
import 'presentation/widgets/settings_feedback.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final mode = ref.watch(themeModeProvider);
    final auth = ref.read(authRepositoryProvider);
    final profileAsync = ref.watch(mobileMeProvider);
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.navSettings)),
        body: SettingsFeedback.loading(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.navSettings)),
        body: SettingsFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.read(settingsProvider.notifier).refresh(),
        ),
      ),
      data: (settingsBundle) {
        return RefreshIndicator(
          onRefresh: () => ref.read(settingsProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Text(l10n.navSettings, style: Theme.of(context).textTheme.headlineSmall),
              if (settingsBundle?.fromCache == true) ...[
                const SizedBox(height: 8),
                SettingsFeedback.offlineHint(context),
              ],
              const SizedBox(height: 16),
              profileAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => Text(l10n.profileLoadError),
                data: (profile) {
                  if (profile == null) return Text(l10n.profileLoadError);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.name, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(profile.phone, style: Theme.of(context).textTheme.bodyMedium),
                      if (profile.email.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(profile.email, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                      if (profile.area != null && profile.area!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(profile.area!, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.profileTitle),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go(AppRoutes.settingsProfile),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(l10n.darkMode),
                subtitle: Text('Theme: ${mode.name}'),
                value: mode == ThemeMode.dark,
                onChanged: (v) async {
                  ref.read(themeModeProvider.notifier).state =
                      v ? ThemeMode.dark : ThemeMode.light;
                  await ref.read(settingsProvider.notifier).syncTheme(
                        v ? SettingsTheme.dark : SettingsTheme.light,
                      );
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: Text(l10n.notificationSettingsTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(AppRoutes.settingsNotifications),
              ),
              ListTile(
                leading: const Icon(Icons.support_agent_outlined),
                title: Text(l10n.supportHelpTitle),
                subtitle: Text(l10n.supportHelpSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(AppRoutes.supportHelp),
              ),
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
              const SizedBox(height: 16),
              const OfflineQueuePanel(),
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: () async {
                  await auth.signOut();
                  if (context.mounted) context.go(AppRoutes.login);
                },
                child: Text(l10n.signOut),
              ),
            ],
          ),
        );
      },
    );
  }
}
