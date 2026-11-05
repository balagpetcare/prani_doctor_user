import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/session/session_auth.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/session/session_manager.dart';
import '../../../routing/app_routes.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/services/profile_completion_service.dart';
import '../../profile/presentation/profile_navigation.dart';
import '../../profile/presentation/profile_providers.dart';
import '../../settings/presentation/settings_providers.dart';

const _authFailureCodes = {
  '401',
  'UNAUTHORIZED',
  'UNAUTHORIZED_BEARER_REQUIRED',
  'TOKEN_INVALID',
  'FORBIDDEN_CUSTOMER_REQUIRED',
};

bool _isAuthFailure(Object error) {
  if (error is! AppException) return false;
  final code = error.code;
  return code != null && _authFailureCodes.contains(code);
}

/// Resolves post-auth destination (home vs profile setup).
Future<void> navigateAfterAuth(BuildContext context, WidgetRef ref) async {
  if (!SessionAuth.canCallProtectedApis(ref.read(sessionControllerProvider))) {
    if (context.mounted) context.go(AppRoutes.login);
    return;
  }

  var meResult = await ref
      .read(profileRepositoryProvider)
      .getMe(forceRefresh: true);
  if (!context.mounted) return;

  var authFailed = meResult.when(
    success: (_) => false,
    failure: _isAuthFailure,
  );
  if (authFailed) {
    final sessionManager = ref.read(sessionManagerProvider);
    final dio = ref.read(dioProvider);
    final recovered = await sessionManager.recoverFromUnauthorized(dio: dio);
    if (recovered) {
      meResult = await ref
          .read(profileRepositoryProvider)
          .getMe(forceRefresh: true);
      if (!context.mounted) return;
      authFailed = meResult.when(
        success: (_) => false,
        failure: _isAuthFailure,
      );
    }
    if (authFailed) {
      await ref
          .read(sessionManagerProvider)
          .invalidateSession(reason: 'post-auth /me failed after refresh');
      if (context.mounted) context.go(AppRoutes.login);
      return;
    }
  }

  final profile = meResult.when(
    success: (data) => data,
    failure: (_) => null,
  );
  final completion = ProfileCompletionService.evaluate(
    profile,
    source: ProfileCompletionSource.server,
  );
  final needsProfile = !completion.profileCompleted;

  ref.invalidate(mobileMeProvider);
  ref.invalidate(settingsProvider);

  if (needsProfile) {
    ProfileCompletionService.logOnboardingDecision(
      decision: 'post-auth-profile-setup',
      status: completion,
      route: profileSetupRoute(profile),
    );
    if (context.mounted) {
      context.go(profileSetupRoute(profile));
    }
  } else {
    ProfileCompletionService.logOnboardingDecision(
      decision: 'post-auth-home',
      status: completion,
      route: AppRoutes.home,
    );
    context.go(AppRoutes.home);
  }
}
