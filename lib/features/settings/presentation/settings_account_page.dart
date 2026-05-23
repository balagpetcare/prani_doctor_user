import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/navigation/navigation_guard.dart';

import '../../../routing/app_routes.dart';
import '../../profile/presentation/profile_providers.dart';
import '../../profile/presentation/widgets/profile_feedback.dart';
import 'widgets/settings_feedback.dart';
import 'widgets/settings_section_header.dart';

class SettingsAccountPage extends ConsumerWidget {
  const SettingsAccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(mobileMeProvider);

    return Scaffold(
      appBar: safeAppBar(context, title: Text(l10n.settingsAccountTitle)),
      body: profileAsync.when(
        loading: SettingsFeedback.loading,
        error: (e, _) => ProfileFeedback.errorFromObject(
          context,
          failure: e,
          onRetry: () =>
              ref.read(mobileMeProvider.notifier).reload(forceRefresh: true),
        ),
        data: (profile) {
          if (profile == null) {
            return SettingsFeedback.error(
              context,
              onRetry: () => ref
                  .read(mobileMeProvider.notifier)
                  .reload(forceRefresh: true),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(mobileMeProvider.notifier).reload(forceRefresh: true),
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline),
                  title: Text(profile.name),
                  subtitle: Text(profile.phone),
                ),
                SettingsSectionHeader(title: l10n.settingsAccountManageTitle),
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Profile appearance'),
                  subtitle: const Text('Photo, cover, display name'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      context.push(AppRoutes.settingsProfileAppearance),
                ),
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Personal information'),
                  subtitle: const Text('Email and phone'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.settingsPersonalInfo),
                ),
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(l10n.addressTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.settingsProfileAddress),
                ),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: Text(l10n.profileChangePasswordTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      context.push(AppRoutes.settingsProfileChangePassword),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
