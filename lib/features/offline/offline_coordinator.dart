import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/offline/offline_dto.dart';
import '../../core/session/session_auth.dart';
import '../../core/session/session_controller.dart';
import '../../core/session/session_state.dart';
import 'data/connectivity_service.dart';
import 'data/sync_coordinator.dart';
import 'offline_providers.dart';

class OfflineCoordinator extends ConsumerStatefulWidget {
  const OfflineCoordinator({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<OfflineCoordinator> createState() => _OfflineCoordinatorState();
}

class _OfflineCoordinatorState extends ConsumerState<OfflineCoordinator> {
  var _initialized = false;
  var _initialSyncDone = false;
  StreamSubscription<OfflineConnectivityMode>? _connectivitySub;
  OfflineConnectivityMode? _lastMode;

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_setup);
  }

  Future<void> _setup() async {
    if (_initialized) return;
    _initialized = true;

    final connectivity = ref.read(connectivityServiceProvider);
    await connectivity.initialize();
    await ref.read(syncCoordinatorProvider).initialize();

    _lastMode = connectivity.currentMode;
    _connectivitySub = connectivity.modeStream.listen((next) {
      if (_lastMode != null &&
          !isOnlineMode(_lastMode!) &&
          isOnlineMode(next)) {
        ref.read(syncCoordinatorProvider).onConnectivityRestored();
      }
      _lastMode = next;
    });

    final session = ref.read(sessionControllerProvider);
    if (SessionAuth.canCallProtectedApis(session)) {
      await ref.read(syncCoordinatorProvider).syncNow(background: true);
      _initialSyncDone = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SessionState>(sessionControllerProvider, (previous, next) {
      final readyAuthed = SessionAuth.canCallProtectedApis(next);
      final wasReadyAuthed =
          previous != null && SessionAuth.canCallProtectedApis(previous);
      if (readyAuthed && !wasReadyAuthed) {
        unawaited(ref.read(syncCoordinatorProvider).syncNow(background: true));
      }
    });

    if (!_initialSyncDone &&
        SessionAuth.canCallProtectedApis(ref.read(sessionControllerProvider))) {
      _initialSyncDone = true;
      unawaited(ref.read(syncCoordinatorProvider).syncNow(background: true));
    }

    return widget.child;
  }
}
