import 'package:flutter/foundation.dart';

/// Structured home-screen performance and load-state logging.
abstract final class HomePerformanceDiagnostics {
  HomePerformanceDiagnostics._();

  static void _log(String tag, String message) {
    if (kDebugMode) debugPrint('[$tag] $message');
  }

  static void homeInit({String? detail}) {
    _log('HOME_INIT', detail ?? '-');
  }

  static void homeBuild({String? detail}) {
    _log('HOME_BUILD', detail ?? '-');
  }

  static void homeRebuild({String? detail}) {
    _log('HOME_REBUILD', detail ?? '-');
  }

  static void apiStart(String endpoint, {String? detail}) {
    _log('HOME_API_START', 'endpoint=$endpoint detail=${detail ?? '-'}');
  }

  static void apiSuccess(String endpoint, {String? detail}) {
    _log('HOME_API_SUCCESS', 'endpoint=$endpoint detail=${detail ?? '-'}');
  }

  static void apiFailure(String endpoint, Object error, {String? detail}) {
    _log(
      'HOME_API_FAILURE',
      'endpoint=$endpoint error=$error detail=${detail ?? '-'}',
    );
  }

  static void providerRefresh(String provider, {String? reason}) {
    _log(
      'HOME_PROVIDER_REFRESH',
      'provider=$provider reason=${reason ?? '-'}',
    );
  }

  static void skeletonTimeout({required Duration elapsed}) {
    _log('HOME_SKELETON_TIMEOUT', 'elapsedMs=${elapsed.inMilliseconds}');
  }
}
