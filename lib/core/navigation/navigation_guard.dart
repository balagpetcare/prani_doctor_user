import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routing/app_routes.dart';



/// Routes that must never show a back button (bottom-nav roots and feature hubs).
abstract final class RootRouteDetector {
  RootRouteDetector._();

  static const shellRootPaths = {
    AppRoutes.home,
    AppRoutes.services,
    AppRoutes.inbox,
    AppRoutes.settings,
  };

  static const featureHubRootPaths = {
    AppRoutes.animals,
    AppRoutes.farms,
    AppRoutes.health,
    AppRoutes.feeds,
    AppRoutes.vaccines,
  };

  static const noBackAppBarPaths = {...shellRootPaths, ...featureHubRootPaths};

  static bool isShellRoot(String location) {
    final path = Uri.tryParse(location)?.path ?? location;
    return shellRootPaths.contains(path);
  }

  static bool isFeatureHubRoot(String location) {
    final path = Uri.tryParse(location)?.path ?? location;
    return featureHubRootPaths.contains(path);
  }

  static bool isRootRoute(String location) {
    final path = Uri.tryParse(location)?.path ?? location;
    return noBackAppBarPaths.contains(path);
  }

  static bool shouldShowBackButton(BuildContext context) {
    final routeCanPop = ModalRoute.of(context)?.canPop ?? false;
    if (!routeCanPop && !context.canPop()) return false;

    final router = GoRouter.maybeOf(context);
    if (router != null && isRootRoute(router.state.matchedLocation)) {
      return false;
    }

    return routeCanPop || context.canPop();
  }
}

/// Debounced pop to avoid double-back on rapid taps.
abstract final class SafePop {
  SafePop._();

  static DateTime? _lastPopAt;
  static const _debounce = Duration(milliseconds: 400);

  static void maybePop(BuildContext context) {
    if (!context.canPop()) return;
    final now = DateTime.now();
    if (_lastPopAt != null && now.difference(_lastPopAt!) < _debounce) return;
    _lastPopAt = now;
    context.pop();
  }
}

/// AppBar that shows back only on non-root pushed routes.
PreferredSizeWidget safeAppBar(
  BuildContext context, {
  required Widget title,
  List<Widget>? actions,
  PreferredSizeWidget? bottom,
}) {
  final showBack = RootRouteDetector.shouldShowBackButton(context);
  return AppBar(
    title: title,
    automaticallyImplyLeading: showBack,
    leading: showBack
        ? IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => SafePop.maybePop(context),
          )
        : null,
    actions: actions,
    bottom: bottom,
  );
}
