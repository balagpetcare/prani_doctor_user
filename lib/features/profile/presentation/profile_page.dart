import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/navigation/navigation_guard.dart';
import '../../../routing/app_routes.dart';
import '../data/mobile_me_dto.dart';
import '../data/profile_media_models.dart';
import 'profile_providers.dart';
import 'widgets/profile_cover_header.dart';
import 'widgets/profile_feedback.dart';
import 'widgets/profile_media_actions.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(mobileMeProvider);

    return Scaffold(
      appBar: safeAppBar(context, title: Text(l10n.profileTitle)),
      body: profileAsync.when(
        loading: ProfileFeedback.loading,
        error: (e, _) => ProfileFeedback.errorFromObject(
          context,
          failure: e,
          onRetry: () =>
              ref.read(mobileMeProvider.notifier).reload(forceRefresh: true),
        ),
        data: (profile) {
          if (profile == null) return ProfileFeedback.empty(context);
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(mobileMeProvider.notifier).reload(forceRefresh: true),
            child: _ProfileBody(profile: profile, l10n: l10n),
          );
        },
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.profile, required this.l10n});

  final MobileMeDto profile;
  final AppLocalizations l10n;

  static String _localeLabel(AppLocalizations l10n, String locale) {
    return locale == 'en-US' ? l10n.languageEnglish : l10n.languageBangla;
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: EdgeInsets.zero,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        ProfileCoverHeader(
          profile: profile,
          l10n: l10n,
          onEditAvatar: () => ProfileMediaActions.showPickerSheet(
            context,
            ref: ref,
            kind: ProfileMediaKind.avatar,
            onMessage: (m) => _snack(context, m),
          ),
          onEditCover: () => ProfileMediaActions.showPickerSheet(
            context,
            ref: ref,
            kind: ProfileMediaKind.cover,
            onMessage: (m) => _snack(context, m),
          ),
          onSettings: () => context.go(AppRoutes.settings),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (profile.needsProfileSetup) ...[
                ActionChip(
                  label: Text(l10n.profileIncomplete),
                  onPressed: () =>
                      context.go(AppRoutes.settingsProfileComplete),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                l10n.profileAccountInfoTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              if (profile.email.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: Text(
                    profile.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (profile.phone.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: Text(
                    profile.phone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(l10n.languageTitle),
                subtitle: Text(_localeLabel(l10n, profile.locale)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(AppRoutes.settingsProfileLanguage),
              ),
              const Divider(height: 32),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Profile appearance'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(AppRoutes.settingsProfileAppearance),
              ),
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Personal information'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(AppRoutes.settingsPersonalInfo),
              ),
              ListTile(
                leading: const Icon(Icons.home_work_outlined),
                title: Text(l10n.addressTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(AppRoutes.settingsProfileAddress),
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: Text(l10n.profileChangePasswordTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(AppRoutes.settingsProfileChangePassword),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
