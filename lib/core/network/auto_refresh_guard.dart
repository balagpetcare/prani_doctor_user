import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls when background/silent network refresh is allowed.
///
/// Allowed only during explicit manual refresh (pull-to-refresh, retry)
/// or a resume refresh after 60s in background.
class AutoRefreshState {
  const AutoRefreshState({
    this.manualRefreshActive = false,
    this.serverReachable = true,
    this.lastResumeRefreshAt,
  });

  final bool manualRefreshActive;
  final bool serverReachable;
  final DateTime? lastResumeRefreshAt;

  AutoRefreshState copyWith({
    bool? manualRefreshActive,
    bool? serverReachable,
    DateTime? lastResumeRefreshAt,
  }) {
    return AutoRefreshState(
      manualRefreshActive: manualRefreshActive ?? this.manualRefreshActive,
      serverReachable: serverReachable ?? this.serverReachable,
      lastResumeRefreshAt: lastResumeRefreshAt ?? this.lastResumeRefreshAt,
    );
  }

  bool get allowSilentNetworkRefresh => manualRefreshActive;
}

class AutoRefreshGuardNotifier extends Notifier<AutoRefreshState> {
  static const resumeMinInterval = Duration(seconds: 60);

  @override
  AutoRefreshState build() => const AutoRefreshState();

  bool get allowSilentNetworkRefresh => state.manualRefreshActive;

  Future<T> runWithManualRefresh<T>(Future<T> Function() action) async {
    state = state.copyWith(manualRefreshActive: true);
    try {
      return await action();
    } finally {
      state = state.copyWith(manualRefreshActive: false);
    }
  }

  void recordApiSuccess() {
    if (!state.serverReachable) {
      state = state.copyWith(serverReachable: true);
    }
  }

  void recordApiFailure() {
    if (state.serverReachable) {
      state = state.copyWith(serverReachable: false);
    }
  }

  bool tryMarkResumeRefresh() {
    final last = state.lastResumeRefreshAt;
    final now = DateTime.now();
    if (last != null && now.difference(last) < resumeMinInterval) {
      return false;
    }
    state = state.copyWith(lastResumeRefreshAt: now);
    return true;
  }
}

final autoRefreshGuardProvider =
    NotifierProvider<AutoRefreshGuardNotifier, AutoRefreshState>(
      AutoRefreshGuardNotifier.new,
    );

extension AutoRefreshRef on Ref {
  bool get allowSilentNetworkRefresh =>
      read(autoRefreshGuardProvider).manualRefreshActive;

  void scheduleSilentRefresh(Future<void> Function() action) {
    if (!allowSilentNetworkRefresh) return;
    unawaited(action());
  }
}

extension AutoRefreshWidgetRef on WidgetRef {
  Future<T> runWithManualRefresh<T>(Future<T> Function() action) {
    return read(autoRefreshGuardProvider.notifier).runWithManualRefresh(action);
  }
}
