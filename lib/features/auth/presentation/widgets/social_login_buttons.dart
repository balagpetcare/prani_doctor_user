import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../data/social_auth_provider.dart';
import 'auth_feedback.dart';

class SocialLoginButtons extends ConsumerWidget {
  const SocialLoginButtons({super.key});

  Future<void> _attempt(
    BuildContext context,
    WidgetRef ref,
    SocialProvider provider,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await ref.read(socialAuthProvider).signIn(provider);
    result.when(
      success: (_) {},
      failure: (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      },
    );
    if (!context.mounted) return;
    if (!ref.read(socialAuthProvider).isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.socialLoginComingSoon)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final social = ref.watch(socialAuthProvider);

    if (!social.isAvailable) {
      return AuthEmptyHint(message: l10n.socialLoginComingSoon);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () => _attempt(context, ref, SocialProvider.google),
          icon: const Icon(Icons.g_mobiledata),
          label: Text(l10n.socialGoogle),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _attempt(context, ref, SocialProvider.facebook),
          icon: const Icon(Icons.facebook),
          label: Text(l10n.socialFacebook),
        ),
      ],
    );
  }
}
