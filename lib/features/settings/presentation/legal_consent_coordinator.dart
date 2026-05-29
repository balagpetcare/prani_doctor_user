import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/session/session_auth.dart';
import '../../../core/session/session_controller.dart';
import '../../../routing/app_routes.dart';
import '../../../routing/legal_consent_gate.dart';
import 'settings_providers.dart';

/// Non-blocking privacy reminder after login when policy version is not accepted.
class LegalConsentCoordinator extends ConsumerWidget {
  const LegalConsentCoordinator({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    if (!SessionAuth.canCallProtectedApis(session)) {
      return child;
    }

    final settings = ref.watch(settingsProvider).valueOrNull;
    final legal = settings?.legal;
    final gate = ref.watch(legalConsentGateProvider);
    final showBanner = legal != null &&
        !legal.privacyAccepted &&
        gate?.needsReconsent != true;

    if (!showBanner) {
      return child;
    }

    final l10n = AppLocalizations.of(context)!;

    return Material(
      child: Column(
        children: [
          MaterialBanner(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: const Icon(Icons.privacy_tip_outlined),
            content: Text(l10n.privacyPolicySubtitle),
            actions: [
              TextButton(
                onPressed: () => context.push(AppRoutes.settingsPrivacy),
                child: Text(l10n.privacyPolicy),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.settingsPrivacy),
                child: Text(l10n.settingsAcceptPrivacy),
              ),
            ],
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
