import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/startup/startup_trace.dart';

/// Escalates from [loadingChild] to [onTimeout] if loading exceeds [timeout].
class AsyncLoadingTimeoutGuard extends StatefulWidget {
  const AsyncLoadingTimeoutGuard({
    super.key,
    required this.isLoading,
    required this.child,
    required this.loadingChild,
    required this.onTimeout,
    this.timeout = const Duration(seconds: 12),
    this.scope = 'async-loading',
  });

  final bool isLoading;
  final Widget child;
  final Widget loadingChild;
  final Widget Function(VoidCallback retry) onTimeout;
  final Duration timeout;
  final String scope;

  @override
  State<AsyncLoadingTimeoutGuard> createState() =>
      _AsyncLoadingTimeoutGuardState();
}

class _AsyncLoadingTimeoutGuardState extends State<AsyncLoadingTimeoutGuard> {
  Timer? _timer;
  bool _timedOut = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    if (widget.isLoading) _armTimer();
  }

  @override
  void didUpdateWidget(covariant AsyncLoadingTimeoutGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      setState(() => _timedOut = false);
      _armTimer();
    } else if (!widget.isLoading) {
      _disarmTimer();
      if (_timedOut) setState(() => _timedOut = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _armTimer() {
    _timer?.cancel();
    final gen = ++_generation;
    _timer = Timer(widget.timeout, () {
      if (!mounted || gen != _generation || !widget.isLoading) return;
      StartupTrace.skeletonTimeout(
        scope: widget.scope,
        elapsed: widget.timeout,
      );
      setState(() => _timedOut = true);
    });
  }

  void _disarmTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _retry() {
    setState(() => _timedOut = false);
    _armTimer();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;
    if (_timedOut) return widget.onTimeout(_retry);
    return widget.loadingChild;
  }
}
