import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/app_routes.dart';
import '../data/mobile_me_dto.dart';
import 'profile_providers.dart';

/// Route for users who still need to finish profile setup.
String profileSetupRoute([MobileMeDto? profile]) {
  if (profile?.canContinueToHome == true) return AppRoutes.home;
  return AppRoutes.settingsProfileComplete;
}

/// After a profile save, pop or go home when setup is complete.
Future<void> navigateAfterProfileSave(
  BuildContext context,
  WidgetRef ref, {
  bool fromCompletionFlow = false,
}) async {
  await ref.read(mobileMeProvider.notifier).reload(forceRefresh: true);
  if (!context.mounted) return;

  final profile = ref.read(mobileMeProvider).value;
  if (profile?.canContinueToHome == true) {
    if (fromCompletionFlow || !context.canPop()) {
      context.go(AppRoutes.home);
    } else {
      context.pop();
    }
    return;
  }

  if (fromCompletionFlow) {
    context.go(AppRoutes.settingsProfileComplete);
    return;
  }

  if (context.canPop()) {
    context.pop();
  }
}
