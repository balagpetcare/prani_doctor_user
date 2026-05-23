import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/auto_refresh_guard.dart';

/// Debug logging for provider lifecycle ([PROVIDER], [REBUILD], [CACHE]).
abstract final class ProviderLog {
  ProviderLog._();

  static void provider(String message) {
    if (kDebugMode) debugPrint('[PROVIDER] $message');
  }

  static void rebuild(String message) {
    if (kDebugMode) debugPrint('[REBUILD] $message');
  }

  static void cache(String message) {
    if (kDebugMode) debugPrint('[CACHE] $message');
  }
}

/// Coalesces identical in-flight async work (request dedup).
class RequestDeduper {
  final Map<String, Future<dynamic>> _inFlight = {};

  Future<T> run<T>(String key, Future<T> Function() task) {
    final existing = _inFlight[key];
    if (existing != null) {
      ProviderLog.rebuild('dedup wait $key');
      return existing.then((value) => value as T);
    }

    ProviderLog.rebuild('dedup start $key');
    final future = task();
    _inFlight[key] = future;
    return future.whenComplete(() {
      _inFlight.remove(key);
      ProviderLog.rebuild('dedup done $key');
    });
  }

  bool isInFlight(String key) => _inFlight.containsKey(key);
}

/// Debounces refresh / invalidate bursts.
class RefreshDebouncer {
  RefreshDebouncer({this.delay = const Duration(milliseconds: 600)});

  final Duration delay;
  Timer? _timer;
  int _scheduled = 0;

  void schedule(Future<void> Function() action) {
    _scheduled++;
    _timer?.cancel();
    _timer = Timer(delay, () async {
      final batch = _scheduled;
      _scheduled = 0;
      ProviderLog.provider('debounced refresh (batch=$batch)');
      try {
        await action();
      } catch (e) {
        ProviderLog.rebuild('debounced refresh failed: $e');
      }
    });
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

final _cacheRevalidateDebouncers = <String, RefreshDebouncer>{};

/// Prefetch fresh data after showing cache — only during manual/resume refresh.
/// Never invalidates on failure (prevents offline rebuild loops).
void scheduleCacheRevalidate(
  Ref ref, {
  required String label,
  required Future<bool> Function() revalidate,
  Duration debounce = const Duration(seconds: 2),
}) {
  if (!ref.allowSilentNetworkRefresh) {
    ProviderLog.cache('skip revalidate $label — auto refresh disabled');
    return;
  }

  ProviderLog.cache('schedule revalidate $label');
  final debouncer = _cacheRevalidateDebouncers.putIfAbsent(
    label,
    () => RefreshDebouncer(delay: debounce),
  );
  debouncer.schedule(() async {
    try {
      final ok = await revalidate();
      if (ok) {
        ref.read(autoRefreshGuardProvider.notifier).recordApiSuccess();
        ProviderLog.cache('invalidate after revalidate $label');
        ref.invalidateSelf();
      } else {
        ref.read(autoRefreshGuardProvider.notifier).recordApiFailure();
        ProviderLog.cache('revalidate failed $label — keep cache');
      }
    } catch (e) {
      ref.read(autoRefreshGuardProvider.notifier).recordApiFailure();
      ProviderLog.rebuild('revalidate error $label: $e');
    }
  });
}

/// Guards against overlapping reload/refresh on [AsyncNotifier]s.
mixin AsyncRefreshGuard<T> on AsyncNotifier<T> {
  bool reloadInFlight = false;
  bool refreshInFlight = false;

  bool get anyRefreshInFlight => reloadInFlight || refreshInFlight;

  bool guardReload() {
    if (reloadInFlight || refreshInFlight) {
      ProviderLog.rebuild('skip reload — in flight');
      return false;
    }
    reloadInFlight = true;
    return true;
  }

  void endReload() => reloadInFlight = false;

  bool guardRefresh({bool silent = false}) {
    if (silent && !ref.allowSilentNetworkRefresh) {
      ProviderLog.rebuild('skip silent refresh — auto refresh disabled');
      return false;
    }
    if (reloadInFlight || refreshInFlight) {
      ProviderLog.rebuild('skip refresh — in flight');
      return false;
    }
    refreshInFlight = true;
    return true;
  }

  void endRefresh() => refreshInFlight = false;
}

extension ProviderKeepAliveRef on Ref {
  void persistProvider(String label) {
    keepAlive();
    ProviderLog.provider('keepAlive $label');
  }
}

/// Returns cached value immediately; optional debounced network refresh.
Future<T> loadWithCache<T>({
  required Ref ref,
  required String label,
  required Future<T?> Function() readCache,
  required Future<T> Function() fetch,
  required Future<bool> Function() revalidate,
}) async {
  final cached = await readCache();
  if (cached != null) {
    ProviderLog.cache('hit $label');
    scheduleCacheRevalidate(ref, label: label, revalidate: revalidate);
    return cached;
  }
  ProviderLog.cache('miss $label');
  return fetch();
}
