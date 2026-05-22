import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/app_routes.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/presentation/profile_providers.dart';

/// Resolves post-auth destination (home vs profile setup).
Future<void> navigateAfterAuth(BuildContext context, WidgetRef ref) async {
  final meResult = await ref.read(profileRepositoryProvider).getMe();
  if (!context.mounted) return;

  final needsProfile = meResult.when(
    success: (profile) => profile.profileComplete == false,
    failure: (_) => false,
  );

  ref.invalidate(mobileMeProvider);

  if (needsProfile) {
    context.go(AppRoutes.settingsProfileEdit);
  } else {
    context.go(AppRoutes.home);
  }
}
