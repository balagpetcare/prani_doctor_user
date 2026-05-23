import 'package:flutter/foundation.dart';

/// Lightweight home dashboard analytics (debug-first; wire to telemetry later).
abstract final class HomeAnalytics {
  HomeAnalytics._();

  static void homeOpened() => _log('home_opened');
  static void pullToRefresh() => _log('home_pull_refresh');
  static void backgroundSyncTriggered() => _log('home_background_sync');
  static void sectionLoaded(String section, {bool fromCache = false}) =>
      _log('home_section_loaded', {'section': section, 'fromCache': fromCache});
  static void sectionError(String section, {String? code}) => _log(
    'home_section_error',
    {'section': section, 'code': ?code},
  );
  static void sectionEmpty(String section) =>
      _log('home_section_empty', {'section': section});
  static void sectionRetry(String section) =>
      _log('home_section_retry', {'section': section});
  static void navigate(String target) =>
      _log('home_navigate', {'target': target});

  static void _log(String event, [Map<String, Object?> params = const {}]) {
    if (kDebugMode) {
      debugPrint('[analytics] $event ${params.isEmpty ? '' : params}');
    }
  }
}
