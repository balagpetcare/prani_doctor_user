import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../startup/startup_trace.dart';
import 'app_logger.dart';
import 'crash_reporting_context.dart';

/// Logs provider failures, slow builds, and rapid update bursts (cycle detection).
final class StartupProviderObserver extends ProviderObserver {
  const StartupProviderObserver();

  static const _cycleWindow = Duration(seconds: 2);
  static const _cycleThreshold = 8;

  static final Map<String, int> _updateCounts = {};
  static Timer? _cycleResetTimer;

  static const _watchedProviders = {
    'dashboardProvider',
    'mobileMeProvider',
    'bootControllerProvider',
    'profileLocationDraftProvider',
    'farmListProvider',
    'notificationListProvider',
  };

  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    _maybeLog(provider, 'INIT');
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    final name = _name(provider);
    if (!_watchedProviders.contains(name)) return;
    StartupTrace.providerEvent(name, 'UPDATE');
    _trackBurst(name);
  }

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    final name = _name(provider);
    StartupTrace.providerEvent(name, 'FAIL', detail: '$error');
    AppLog.error(
      'Provider failure: $name',
      tag: 'Riverpod',
      error: error,
      stackTrace: stackTrace,
      fatal: false,
      data: {
        'category': CrashErrorCategory.providerFailure,
        'provider': name,
      },
    );
  }

  void _maybeLog(ProviderBase<Object?> provider, String event) {
    final name = _name(provider);
    if (!_watchedProviders.contains(name)) return;
    StartupTrace.providerEvent(name, event);
  }

  void _trackBurst(String name) {
    _updateCounts[name] = (_updateCounts[name] ?? 0) + 1;
    _cycleResetTimer?.cancel();
    _cycleResetTimer = Timer(_cycleWindow, _updateCounts.clear);

    final count = _updateCounts[name] ?? 0;
    if (count >= _cycleThreshold) {
      StartupTrace.providerEvent(
        name,
        'CYCLE',
        detail: 'updates=$count/${_cycleWindow.inSeconds}s',
      );
      if (kDebugMode) {
        debugPrint(
          '[PROVIDER_CYCLE] $name updated $count times in '
          '${_cycleWindow.inSeconds}s — possible refresh loop',
        );
      }
    }
  }

  String _name(ProviderBase<Object?> provider) =>
      provider.name ?? provider.runtimeType.toString();
}
