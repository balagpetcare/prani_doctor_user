import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../routing/app_routes.dart';
import 'navigation_guard.dart';

/// Central back-navigation rules for shell roots, feature hubs, and pushed routes.
abstract final class NavigationService {
  NavigationService._();

  static bool isShellRoot(String location) =>
      RootRouteDetector.isShellRoot(location);

  static Future<bool> showExitDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.exitAppTitle),
        content: Text(l10n.exitAppMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.exitAppConfirm),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  static Future<bool> showLogoutDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.logoutConfirmTitle),
        content: Text(l10n.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  /// Handles system back. Returns `true` when the app should exit.
  static Future<bool> handleBack(BuildContext context) async {
    if (context.canPop()) {
      SafePop.maybePop(context);
      return false;
    }

    final router = GoRouter.maybeOf(context);
    final location = router?.state.matchedLocation ?? AppRoutes.home;

    if (RootRouteDetector.isShellRoot(location)) {
      return showExitDialog(context);
    }

    if (RootRouteDetector.isFeatureHubRoot(location)) {
      context.go(AppRoutes.home);
      return false;
    }

    return showExitDialog(context);
  }

  static Future<void> onBackInvoked(BuildContext context) async {
    final shouldExit = await handleBack(context);
    if (shouldExit && context.mounted) {
      await SystemNavigator.pop();
    }
  }
}

/// Wraps a screen to intercept device back via [NavigationService].
class NavigationBackHandler extends StatelessWidget {
  const NavigationBackHandler({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        NavigationService.onBackInvoked(context);
      },
      child: child,
    );
  }
}
