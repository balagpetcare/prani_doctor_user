import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/presentation/settings_providers.dart';
import 'app_routes.dart';

/// Derived legal consent gate from cached/API settings bundle.
class LegalConsentGate {
  const LegalConsentGate({
    required this.needsReconsent,
    required this.needsAiConsent,
    required this.enforcePrivacyConsent,
  });

  final bool needsReconsent;
  final bool needsAiConsent;
  final bool enforcePrivacyConsent;
}

final legalConsentGateProvider = Provider<LegalConsentGate?>((ref) {
  final bundle = ref.watch(settingsProvider).valueOrNull;
  if (bundle == null) return null;
  final legal = bundle.legal;
  return LegalConsentGate(
    needsReconsent: legal.legalGateEnabled && legal.needsLegalGate,
    needsAiConsent: !legal.aiConsentAccepted,
    enforcePrivacyConsent: legal.enforcePrivacyConsent,
  );
});

bool isLegalConsentExemptRoute(String location) {
  return location == AppRoutes.reconsent ||
      location == AppRoutes.settingsPrivacy ||
      location == AppRoutes.settingsTerms ||
      location == AppRoutes.settingsAiConsent ||
      location == AppRoutes.settingsProfileComplete ||
      location.startsWith('${AppRoutes.settingsProfile}/');
}

bool isAiConsentGatedRoute(String location) {
  return location == AppRoutes.ai ||
      location.startsWith('${AppRoutes.ai}/') ||
      location == AppRoutes.aiChat ||
      location.startsWith('${AppRoutes.aiChat}/');
}
