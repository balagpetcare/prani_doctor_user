import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routing/app_routes.dart';
import 'navigation_diagnostics.dart';
import 'navigation_guard.dart';

/// Safe tab switching and shell stack recovery for [StatefulNavigationShell].
abstract final class ShellNavigation {
  ShellNavigation._();

  static const branchRoots = <String>[
    AppRoutes.home,
    AppRoutes.services,
    AppRoutes.inbox,
    AppRoutes.settings,
  ];

  static String rootForBranch(int index) {
    if (index < 0 || index >= branchRoots.length) {
      return AppRoutes.home;
    }
    return branchRoots[index];
  }

  /// Switches bottom-nav tabs without corrupting the indexed stack.
  static void selectTab(
    BuildContext context, {
    required StatefulNavigationShell shell,
    required int index,
  }) {
    if (index < 0 || index >= branchRoots.length) return;

    final from = shell.currentIndex;
    final targetRoot = rootForBranch(index);

    NavigationDiagnostics.navigationStart(
      action: 'shell-tab',
      from: '$from',
      to: '$index',
      route: targetRoot,
    );

    try {
      if (from == index) {
        shell.goBranch(index, initialLocation: true);
      } else {
        shell.goBranch(index);
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        recoverShellIfNeeded(context, shell);
        NavigationDiagnostics.navigationEnd(
          action: 'shell-tab',
          route: GoRouter.of(context).state.matchedLocation,
        );
      });
    } catch (e, st) {
      NavigationDiagnostics.navigationEnd(
        action: 'shell-tab',
        route: targetRoot,
        success: false,
      );
      if (kDebugMode) {
        debugPrint('[ShellNavigation] tab switch failed: $e\n$st');
      }
      if (context.mounted) {
        context.go(targetRoot);
      }
    }
  }

  /// Ensures the active shell branch shows its root when the stack desyncs.
  static void recoverShellIfNeeded(
    BuildContext context,
    StatefulNavigationShell shell,
  ) {
    if (!context.mounted) return;

    final router = GoRouter.of(context);
    final location = router.state.matchedLocation;
    final expectedRoot = rootForBranch(shell.currentIndex);

    final onExpectedBranch =
        location == expectedRoot || location.startsWith('$expectedRoot/');

    if (RootRouteDetector.isShellRoot(location) && onExpectedBranch) {
      return;
    }

    // Root overlay routes (e.g. /search) are valid — do not force shell reset.
    if (!RootRouteDetector.isShellRoot(location) &&
        !location.startsWith('/home') &&
        !location.startsWith('/services') &&
        !location.startsWith('/inbox') &&
        !location.startsWith('/settings')) {
      return;
    }

    NavigationDiagnostics.navigationStart(
      action: 'shell-recover',
      from: location,
      to: expectedRoot,
    );
    router.go(expectedRoot);
    NavigationDiagnostics.navigationEnd(
      action: 'shell-recover',
      route: expectedRoot,
    );
  }

  /// Navigates to another shell tab root without leaving the indexed stack.
  static void goShellRoot(BuildContext context, String shellRoot) {
    NavigationDiagnostics.navigationStart(
      action: 'go-shell-root',
      to: shellRoot,
      route: shellRoot,
    );
    context.go(shellRoot);
    NavigationDiagnostics.navigationEnd(action: 'go-shell-root', route: shellRoot);
  }
}
