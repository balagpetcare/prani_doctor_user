import 'package:flutter/foundation.dart';

/// Cold-start timeline markers for diagnosing ANR / freeze during boot.
abstract final class StartupTrace {
  StartupTrace._();

  static final Stopwatch _clock = Stopwatch();
  static final Map<String, int> _marks = {};
  static bool _started = false;

  static void _ensureStarted() {
    if (_started) return;
    _started = true;
    _clock.start();
  }

  static void _log(String tag, {String? detail}) {
    if (!kDebugMode) return;
    _ensureStarted();
    final elapsed = _clock.elapsedMilliseconds;
    _marks[tag] = elapsed;
    debugPrint('[$tag] elapsedMs=$elapsed detail=${detail ?? '-'}');
  }

  static Map<String, int> get timeline => Map.unmodifiable(_marks);

  static int? elapsedSince(String tag) {
    final mark = _marks[tag];
    if (mark == null) return null;
    _ensureStarted();
    return _clock.elapsedMilliseconds - mark;
  }

  static void appStart({String? detail}) => _log('APP_START', detail: detail);

  /// Generic timeline marker (e.g. BOOTSTRAP_BEGIN, RUN_APP).
  static void mark(String tag, {String? detail}) => _log(tag, detail: detail);

  static void splashStart({String? detail}) => _log('SPLASH_START', detail: detail);

  static void authCheckStart({String? detail}) =>
      _log('AUTH_CHECK_START', detail: detail);

  static void profileLoadStart({String? detail}) =>
      _log('PROFILE_LOAD_START', detail: detail);

  static void locationLoadStart({String? detail}) =>
      _log('LOCATION_LOAD_START', detail: detail);

  static void homeLoadStart({String? detail}) =>
      _log('HOME_LOAD_START', detail: detail);

  static void homeRendered({String? detail}) =>
      _log('HOME_RENDERED', detail: detail);

  static void apiStart(String endpoint, {String? detail}) =>
      _log('APP_API_START', detail: 'endpoint=$endpoint ${detail ?? ''}'.trim());

  static void apiSuccess(String endpoint, {String? detail}) => _log(
    'APP_API_SUCCESS',
    detail: 'endpoint=$endpoint ${detail ?? ''}'.trim(),
  );

  static void apiFailure(String endpoint, Object error, {String? detail}) =>
      _log(
        'APP_API_FAILURE',
        detail: 'endpoint=$endpoint error=$error ${detail ?? ''}'.trim(),
      );

  static void providerEvent(String provider, String event, {String? detail}) =>
      _log(
        'PROVIDER_$event',
        detail: 'provider=$provider ${detail ?? ''}'.trim(),
      );

  static void skeletonTimeout({required String scope, required Duration elapsed}) =>
      _log(
        'SKELETON_TIMEOUT',
        detail: 'scope=$scope elapsedMs=${elapsed.inMilliseconds}',
      );

  static void resetForTest() {
    _marks.clear();
    _clock
      ..reset()
      ..stop();
    _started = false;
  }
}
