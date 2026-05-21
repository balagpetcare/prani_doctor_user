import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../routing/app_routes.dart';
import '../profile/presentation/profile_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(mobileMeProvider);

    return profileAsync.when(
      loading: () => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l10n.navHome, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
      error: (_, __) => Center(
        child: Text(l10n.navHome, style: Theme.of(context).textTheme.headlineSmall),
      ),
      data: (profile) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.navHome, style: Theme.of(context).textTheme.headlineSmall),
                if (profile != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    profile.name,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(profile.phone, style: Theme.of(context).textTheme.bodyLarge),
                  if (profile.area != null && profile.area!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      profile.area!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => context.go(AppRoutes.settingsProfile),
                    child: Text(l10n.editProfile),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
