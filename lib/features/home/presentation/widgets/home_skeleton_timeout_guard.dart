import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/startup/startup_trace.dart';
import '../../data/home_api_guard.dart';
import '../home_performance_diagnostics.dart';
import 'home_load_failure_view.dart';
import 'home_page_skeleton.dart';

/// Escalates from skeleton to retry UI if dashboard load exceeds [timeout].
class HomeSkeletonTimeoutGuard extends StatefulWidget {
  const HomeSkeletonTimeoutGuard({
    super.key,
    required this.onRetry,
    this.timeout = HomeApiGuard.skeletonMaxDisplay,
    this.message = HomeLoadFailureView.defaultMessageBn,
  });

  final VoidCallback onRetry;
  final Duration timeout;
  final String message;

  @override
  State<HomeSkeletonTimeoutGuard> createState() =>
      _HomeSkeletonTimeoutGuardState();
}

class _HomeSkeletonTimeoutGuardState extends State<HomeSkeletonTimeoutGuard> {
  Timer? _timer;
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.timeout, () {
      if (!mounted) return;
      HomePerformanceDiagnostics.skeletonTimeout(elapsed: widget.timeout);
      StartupTrace.skeletonTimeout(scope: 'home-dashboard', elapsed: widget.timeout);
      setState(() => _timedOut = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _retry() {
    setState(() => _timedOut = false);
    _timer?.cancel();
    _timer = Timer(widget.timeout, () {
      if (!mounted) return;
      HomePerformanceDiagnostics.skeletonTimeout(elapsed: widget.timeout);
      StartupTrace.skeletonTimeout(scope: 'home-dashboard', elapsed: widget.timeout);
      setState(() => _timedOut = true);
    });
    widget.onRetry();
  }

  @override
  Widget build(BuildContext context) {
    if (_timedOut) {
      return HomeLoadFailureView(message: widget.message, onRetry: _retry);
    }
    return const HomePageSkeleton();
  }
}
