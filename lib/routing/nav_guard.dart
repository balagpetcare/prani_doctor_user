import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/session/session_controller.dart';
import '../features/boot/boot_controller.dart';
import '../features/onboarding/presentation/onboarding_providers.dart';
import '../features/profile/presentation/profile_navigation.dart';
import '../features/profile/presentation/profile_providers.dart';
import 'app_routes.dart';
import 'legal_consent_gate.dart';

/// High-level navigation auth phase (loading / guest / authenticated).
enum NavPhase { loading, guest, authenticated }

/// Debug logging for navigation decisions.
abstract final class NavLog {
  NavLog._();

  static void nav(String message) {
    if (kDebugMode) debugPrint('[NAV] $message');
  }

  static void redirect(String from, String? to, String reason) {
    if (!kDebugMode) return;
    if (to == null) {
      debugPrint('[REDIRECT] stay on $from ($reason)');
    } else {
      debugPrint('[REDIRECT] $from → $to ($reason)');
    }
  }
}

/// Derived from boot + session; drives [GoRouter] redirect only.
final navPhaseProvider = Provider<NavPhase>((ref) {
  final boot = ref.watch(bootControllerProvider);
  final session = ref.watch(sessionControllerProvider);

  if (!boot.isReady || !session.sessionReady) {
    return NavPhase.loading;
  }
  if (session.isAuthenticated) {
    return NavPhase.authenticated;
  }
  return NavPhase.guest;
});

bool isPublicAuthRoute(String location) {
  return location == AppRoutes.login ||
      location == AppRoutes.register ||
      location == AppRoutes.otp ||
      location == AppRoutes.forgotPassword;
}

bool isGuestPublicRoute(String location) {
  return isPublicAuthRoute(location) ||
      location == AppRoutes.onboarding ||
      location == AppRoutes.welcome;
}

String? guestEntryRoute(Ref ref) {
  final onboarding = ref.read(onboardingCompletedProvider);
  return onboarding.when(
    data: (completed) => completed ? AppRoutes.login : AppRoutes.onboarding,
    loading: () => null,
    error: (_, _) => AppRoutes.onboarding,
  );
}

String? authenticatedBootExit(Ref ref) {
  final profile = ref.read(mobileMeProvider).value;
  if (profile?.needsProfileSetup == true) {
    return profileSetupRoute(profile);
  }
  final gate = ref.read(legalConsentGateProvider);
  if (gate?.needsReconsent == true) {
    return AppRoutes.reconsent;
  }
  return AppRoutes.home;
}

String? authenticatedConsentRedirect(Ref ref, String location) {
  if (isLegalConsentExemptRoute(location)) return null;
  final gate = ref.read(legalConsentGateProvider);
  if (gate == null) return null;
  if (gate.needsReconsent) return AppRoutes.reconsent;
  if (isAiConsentGatedRoute(location) && gate.needsAiConsent) {
    return AppRoutes.settingsAiConsent;
  }
  return null;
}

/// Single redirect evaluator — sync only; no [context.go] from widgets during boot.
String? resolveRedirect({required Ref ref, required GoRouterState state}) {
  final location = state.matchedLocation;
  final phase = ref.read(navPhaseProvider);
  final boot = ref.read(bootControllerProvider);

  final isBoot = location == AppRoutes.boot;
  final isWelcome = location == AppRoutes.welcome;
  final isOnboarding = location == AppRoutes.onboarding;

  String? decide(String? target, String reason) {
    if (target == null || target == location) {
      NavLog.redirect(location, null, reason);
      return null;
    }
    NavLog.redirect(location, target, reason);
    return target;
  }

  // Boot overlays (force update, maintenance, optional update, error).
  if (!boot.isReady) {
    if (boot.forceUpdateRequired ||
        boot.maintenanceActive ||
        boot.optionalUpdatePending ||
        boot.hasError) {
      return decide(isBoot ? null : AppRoutes.boot, 'boot-blocked');
    }
    return decide(isBoot ? null : AppRoutes.boot, 'boot-loading');
  }

  switch (phase) {
    case NavPhase.loading:
      return decide(isBoot ? null : AppRoutes.boot, 'session-loading');

    case NavPhase.guest:
      if (isBoot) {
        return decide(guestEntryRoute(ref), 'boot-exit-guest');
      }
      if (isGuestPublicRoute(location)) {
        return decide(null, 'guest-public');
      }
      return decide(guestEntryRoute(ref), 'guest-guard');

    case NavPhase.authenticated:
      if (isBoot) {
        return decide(authenticatedBootExit(ref), 'boot-exit-authenticated');
      }
      if (isPublicAuthRoute(location) || isWelcome) {
        return decide(AppRoutes.home, 'authenticated-away-from-auth');
      }
      if (isOnboarding) {
        return decide(AppRoutes.home, 'authenticated-skip-onboarding');
      }
      final consentTarget = authenticatedConsentRedirect(ref, location);
      if (consentTarget != null) {
        return decide(consentTarget, 'legal-consent-gate');
      }
      return decide(null, 'authenticated-allowed');
  }
}
