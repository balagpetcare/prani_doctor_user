import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/app_routes.dart';
import '../../../core/session/session_controller.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final session = ref.read(sessionControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.loginTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: () async {
                await session.signInDevPlaceholder();
                if (context.mounted) context.go(AppRoutes.home);
              },
              child: Text(l10n.loginDevContinue),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                // Wire to AuthRepository.signInWithGoogle when ready
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Connect GoogleSignIn in AuthRepository')),
                );
              },
              child: const Text('Google'),
            ),
            OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Connect Facebook Auth in AuthRepository')),
                );
              },
              child: const Text('Facebook'),
            ),
          ],
        ),
      ),
    );
  }
}

