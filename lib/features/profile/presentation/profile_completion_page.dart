import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/navigation/navigation_guard.dart';
import '../../../routing/app_routes.dart';
import '../data/mobile_me_dto.dart';
import 'profile_providers.dart';
import 'widgets/profile_feedback.dart';

class ProfileCompletionPage extends ConsumerStatefulWidget {
  const ProfileCompletionPage({super.key});

  @override
  ConsumerState<ProfileCompletionPage> createState() =>
      _ProfileCompletionPageState();
}

class _ProfileCompletionPageState extends ConsumerState<ProfileCompletionPage> {
  bool _continuing = false;

  void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }

  Future<void> _continueToHome(MobileMeDto profile) async {
    if (!profile.canContinueToHome || _continuing) return;

    _log('[PROFILE_COMPLETE] continue tapped');
    setState(() => _continuing = true);

    await ref.read(mobileMeProvider.notifier).reload(forceRefresh: true);
    if (!mounted) return;

    final refreshed = ref.read(mobileMeProvider).value;
    final canProceed =
        refreshed?.canContinueToHome == true || profile.canContinueToHome;
    if (!canProceed) {
      _log('[PROFILE_COMPLETE] blocked after refresh — requirements not met');
      setState(() => _continuing = false);
      return;
    }

    _log('[CONTINUE_ENABLED] navigating to home');
    if (mounted) context.go(AppRoutes.home);
    if (mounted) setState(() => _continuing = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(mobileMeProvider);

    return Scaffold(
      appBar: safeAppBar(context, title: Text(l10n.profileCompletionTitle)),
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

          final canContinue = profile.canContinueToHome;
          if (canContinue) {
            _log(
              '[CONTINUE_ENABLED] name=${profile.name.isNotEmpty} union=${profile.address?.unionId}',
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(mobileMeProvider.notifier).reload(forceRefresh: true),
            child: ListView(
              padding: const EdgeInsets.all(24),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Text(
                  l10n.profileCompletionSubtitle,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                _SetupStepTile(
                  done: profile.hasDisplayName,
                  title: l10n.profileCompletionNameStep,
                  onTap: () => context.push(AppRoutes.settingsPersonalInfo),
                ),
                _SetupStepTile(
                  done: profile.hasRequiredLocation,
                  title: l10n.profileCompletionAddressStep,
                  onTap: () => context.push(AppRoutes.settingsProfileAddress),
                ),
                _SetupStepTile(
                  done: profile.profilePhotoUrl?.isNotEmpty ?? false,
                  title: l10n.profileCompletionPhotoStep,
                  optional: true,
                  onTap: () => context.push(AppRoutes.settingsProfileEdit),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: canContinue && !_continuing
                      ? () => _continueToHome(profile)
                      : null,
                  child: _continuing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.profileCompletionContinue),
                ),
                if (!canContinue) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.profileCompletionHint,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
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

class _SetupStepTile extends StatelessWidget {
  const _SetupStepTile({
    required this.done,
    required this.title,
    required this.onTap,
    this.optional = false,
  });

  final bool done;
  final String title;
  final VoidCallback onTap;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        done ? Icons.check_circle : Icons.radio_button_unchecked,
        color: done
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outline,
      ),
      title: Text(title),
      subtitle: optional ? Text(l10n.profileCompletionOptional) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
