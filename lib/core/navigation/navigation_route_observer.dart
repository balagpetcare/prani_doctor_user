import 'package:flutter/material.dart';

import 'navigation_diagnostics.dart';

/// Logs [ROUTE_ENTER] / [ROUTE_EXIT] for all navigator transitions.
class NavigationRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    NavigationDiagnostics.routeEnter(
      _label(route),
      source: previousRoute != null ? _label(previousRoute) : null,
    );
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    NavigationDiagnostics.routeExit(
      _label(route),
      destination: previousRoute != null ? _label(previousRoute) : null,
    );
    if (previousRoute != null &&
        (_label(previousRoute).contains('home') ||
            _label(previousRoute) == '/home')) {
      NavigationDiagnostics.homeRebuild(phase: 'visible-after-pop');
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (oldRoute != null) {
      NavigationDiagnostics.routeExit(_label(oldRoute), destination: 'replace');
    }
    if (newRoute != null) {
      NavigationDiagnostics.routeEnter(_label(newRoute), source: 'replace');
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    NavigationDiagnostics.routeExit(_label(route), destination: 'remove');
  }

  String _label(Route<dynamic> route) {
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) return name;
    return route.settings.arguments?.toString() ?? route.runtimeType.toString();
  }
}
