import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../logging/app_logger.dart';
import '../logging/crash_reporting_context.dart';
import 'navigation_diagnostics.dart';
import 'navigation_guard.dart' show SafePop;

/// Crash-safe navigation helpers that log failures instead of taking down the app.
abstract final class SafeNavigation {
  SafeNavigation._();

  static void go(BuildContext context, String location, {Object? extra}) {
    if (!_mounted(context)) return;
    NavigationDiagnostics.navigationStart(
      action: 'go',
      to: location,
      route: location,
    );
    try {
      context.go(location, extra: extra);
      NavigationDiagnostics.navigationEnd(action: 'go', route: location);
    } catch (e, st) {
      NavigationDiagnostics.navigationEnd(
        action: 'go',
        route: location,
        success: false,
      );
      AppLog.error(
        'Navigation.go failed',
        tag: 'Nav',
        error: e,
        stackTrace: st,
        data: {'location': location, 'category': CrashErrorCategory.navigation},
      );
    }
  }

  static void push(BuildContext context, String location, {Object? extra}) {
    if (!_mounted(context)) return;
    NavigationDiagnostics.navigationStart(
      action: 'push',
      to: location,
      route: location,
    );
    try {
      context.push(location, extra: extra);
      NavigationDiagnostics.navigationEnd(action: 'push', route: location);
    } catch (e, st) {
      NavigationDiagnostics.navigationEnd(
        action: 'push',
        route: location,
        success: false,
      );
      AppLog.error(
        'Navigation.push failed',
        tag: 'Nav',
        error: e,
        stackTrace: st,
        data: {'location': location, 'category': CrashErrorCategory.navigation},
      );
    }
  }

  static void replace(BuildContext context, String location, {Object? extra}) {
    if (!_mounted(context)) return;
    NavigationDiagnostics.navigationStart(
      action: 'replace',
      to: location,
      route: location,
    );
    try {
      context.replace(location, extra: extra);
      NavigationDiagnostics.navigationEnd(action: 'replace', route: location);
    } catch (e, st) {
      NavigationDiagnostics.navigationEnd(
        action: 'replace',
        route: location,
        success: false,
      );
      AppLog.error(
        'Navigation.replace failed',
        tag: 'Nav',
        error: e,
        stackTrace: st,
        data: {'location': location, 'category': CrashErrorCategory.navigation},
      );
    }
  }

  /// Delegates to [SafePop.maybePop] (debounced).
  static void pop(BuildContext context) => SafePop.maybePop(context);

  static bool _mounted(BuildContext context) {
    if (!context.mounted) {
      AppLog.warn('Navigation skipped: context unmounted', tag: 'Nav');
      return false;
    }
    return true;
  }
}
