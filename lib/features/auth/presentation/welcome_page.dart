import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import '../data/auth_preferences.dart';
import '../data/social_auth_provider.dart';
import 'auth_providers.dart';
import 'widgets/auth_feedback.dart';

class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  Future<void> _continue(BuildContext context, WidgetRef ref) async {
    await ref.read(authPreferencesProvider).setWelcomeSeen(true);
    ref.invalidate(welcomeSeenProvider);
    if (context.mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final social = ref.watch(socialAuthProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Spacer(),
              Icon(Icons.pets, size: 88, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                l10n.welcomeTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.welcomeSubtitle,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => _continue(context, ref),
                child: Text(l10n.welcomeGetStarted),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go(AppRoutes.register),
                child: Text(l10n.createAccount),
              ),
              if (!social.isAvailable) ...[
                const SizedBox(height: 24),
                AuthEmptyHint(message: l10n.socialLoginComingSoon),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
