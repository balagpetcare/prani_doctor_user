import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pranidoctor_user/l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';
import '../../../core/session/session_controller.dart';
import '../../../theme/theme_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final mode = ref.watch(themeModeProvider);
    final session = ref.read(sessionControllerProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.navSettings, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Dark mode'),
          subtitle: Text('Theme: ${mode.name}'),
          value: mode == ThemeMode.dark,
          onChanged: (v) {
            ref.read(themeModeProvider.notifier).state =
                v ? ThemeMode.dark : ThemeMode.light;
          },
        ),
        const SizedBox(height: 24),
        FilledButton.tonal(
          onPressed: () async {
            await session.signOut();
            if (context.mounted) context.go(AppRoutes.login);
          },
          child: const Text('Sign out'),
        ),
      ],
    );
  }
}
