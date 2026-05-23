import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/home/presentation/home_navigation.dart';
import 'auto_refresh_guard.dart';

/// Refreshes dashboard only after app was backgrounded for 60+ seconds.
class AppLifecycleCoordinator extends ConsumerStatefulWidget {
  const AppLifecycleCoordinator({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLifecycleCoordinator> createState() =>
      _AppLifecycleCoordinatorState();
}

class _AppLifecycleCoordinatorState extends ConsumerState<AppLifecycleCoordinator>
    with WidgetsBindingObserver {
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pausedAt ??= DateTime.now();
      return;
    }

    if (state != AppLifecycleState.resumed) return;

    final pausedAt = _pausedAt;
    _pausedAt = null;
    if (pausedAt == null) return;

    final awayFor = DateTime.now().difference(pausedAt);
    if (awayFor < AutoRefreshGuardNotifier.resumeMinInterval) return;

    final guard = ref.read(autoRefreshGuardProvider.notifier);
    if (!guard.tryMarkResumeRefresh()) return;

    unawaited(
      guard.runWithManualRefresh(
        () => HomeNavigation.refreshDashboard(ref),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
