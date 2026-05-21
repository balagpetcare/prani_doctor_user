import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pranidoctor_user/l10n/app_localizations.dart';
import '../../app/app_env.dart';
import '../../../routing/app_routes.dart';
import '../../../theme/theme_controller.dart';
import '../auth/data/auth_repository.dart';
import '../offline/presentation/offline_queue_panel.dart';
import '../profile/presentation/profile_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse(AppEnv.fromEnvironment().privacyPolicyUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      debugPrint('Could not open privacy policy: $uri');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final mode = ref.watch(themeModeProvider);
    final auth = ref.read(authRepositoryProvider);
    final profileAsync = ref.watch(mobileMeProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.navSettings, style: Theme.of(context).textTheme.headlineSmall),
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
                  title: Text(l10n.editProfile),
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
          onChanged: (v) {
            ref.read(themeModeProvider.notifier).state =
                v ? ThemeMode.dark : ThemeMode.light;
          },
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: Text(l10n.privacyPolicy),
          subtitle: Text(l10n.privacyPolicySubtitle),
          trailing: const Icon(Icons.open_in_new),
          onTap: _openPrivacyPolicy,
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
    );
  }
}
