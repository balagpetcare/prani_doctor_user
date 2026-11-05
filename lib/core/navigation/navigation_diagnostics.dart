import 'package:flutter/foundation.dart';

/// Structured navigation logging for diagnosing blank-screen / stack issues.
abstract final class NavigationDiagnostics {
  NavigationDiagnostics._();

  static void _log(String tag, String message) {
    if (kDebugMode) debugPrint('[$tag] $message');
  }

  static void navigationStart({
    required String action,
    String? from,
    String? to,
    String? route,
  }) {
    _log(
      'NAVIGATION_START',
      'action=$action from=${from ?? '-'} to=${to ?? '-'} route=${route ?? '-'}',
    );
  }

  static void navigationEnd({
    required String action,
    String? route,
    bool? success,
  }) {
    _log(
      'NAVIGATION_END',
      'action=$action route=${route ?? '-'} success=${success ?? true}',
    );
  }

  static void routeEnter(String route, {String? source}) {
    _log('ROUTE_ENTER', 'route=$route source=${source ?? '-'}');
  }

  static void routeExit(String route, {String? destination}) {
    _log('ROUTE_EXIT', 'route=$route destination=${destination ?? '-'}');
  }

  static void homeRebuild({required String phase, String? detail}) {
    _log('HOME_REBUILD', 'phase=$phase detail=${detail ?? '-'}');
  }
}
