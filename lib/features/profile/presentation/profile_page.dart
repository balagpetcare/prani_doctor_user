import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import '../data/mobile_me_dto.dart';
import 'profile_providers.dart';
import 'widgets/profile_feedback.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(mobileMeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: profileAsync.when(
        loading: () => ProfileFeedback.loading(),
        error: (_, __) => ProfileFeedback.error(
          context,
          onRetry: () => ref.read(mobileMeProvider.notifier).reload(forceRefresh: true),
        ),
        data: (profile) {
          if (profile == null) return ProfileFeedback.empty(context);
          return _ProfileBody(profile: profile, l10n: l10n);
        },
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.profile, required this.l10n});

  final MobileMeDto profile;
  final AppLocalizations l10n;

  static String _localeLabel(AppLocalizations l10n, String locale) {
    return locale == 'en-US' ? l10n.languageEnglish : l10n.languageBangla;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Column(
            children: [
              ProfileAvatar(
                photoUrl: profile.profilePhotoUrl,
                name: profile.name,
                radius: 48,
              ),
              const SizedBox(height: 12),
              Text(profile.name, style: Theme.of(context).textTheme.titleLarge),
              Text(profile.phone, style: Theme.of(context).textTheme.bodyMedium),
              if (profile.profileComplete == false) ...[
                const SizedBox(height: 8),
                Chip(label: Text(l10n.profileIncomplete)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (profile.email.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: Text(profile.email),
          ),
        if (profile.area != null && profile.area!.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: Text(profile.area!),
          ),
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(l10n.languageTitle),
          subtitle: Text(_localeLabel(l10n, profile.locale)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go(AppRoutes.settingsProfileLanguage),
        ),
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: Text(l10n.editProfile),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go(AppRoutes.settingsProfileEdit),
        ),
        ListTile(
          leading: const Icon(Icons.home_work_outlined),
          title: Text(l10n.addressTitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go(AppRoutes.settingsProfileAddress),
        ),
      ],
    );
  }
}
