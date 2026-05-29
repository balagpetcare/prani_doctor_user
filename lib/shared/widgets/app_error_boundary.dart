import 'package:flutter/material.dart';

import '../../core/logging/app_logger.dart';
import 'app_graceful_error.dart';

/// Catches synchronous errors thrown while building [child] and shows a
/// fallback instead of crashing the whole app.
///
/// Note: this only guards the **immediate** [build] of [child]. Async errors
/// in [child]'s descendants are handled by [GlobalErrorHandler] / zones.
///
/// Wrap high-risk subtrees (charts, WebViews, experimental features):
/// ```dart
/// AppErrorBoundary(child: FatteningChartSection()),
/// ```
class AppErrorBoundary extends StatefulWidget {
  const AppErrorBoundary({
    super.key,
    required this.child,
    this.fallback,
    this.onError,
  });

  final Widget child;
  final Widget Function(FlutterErrorDetails details)? fallback;
  final void Function(FlutterErrorDetails details)? onError;

  @override
  State<AppErrorBoundary> createState() => _AppErrorBoundaryState();
}

class _AppErrorBoundaryState extends State<AppErrorBoundary> {
  FlutterErrorDetails? _details;

  @override
  Widget build(BuildContext context) {
    if (_details != null) {
      return widget.fallback?.call(_details!) ??
          AppGracefulErrorWidget(
            details: _details!,
            onRetry: () => setState(() => _details = null),
          );
    }

    return _ErrorCatcher(
      onError: (details) {
        AppLog.error(
          'AppErrorBoundary caught build error',
          tag: 'UI',
          error: details.exception,
          stackTrace: details.stack,
        );
        widget.onError?.call(details);
        setState(() => _details = details);
      },
      child: widget.child,
    );
  }
}

/// Delegates to Flutter's error reporting for build-phase failures.
class _ErrorCatcher extends StatelessWidget {
  const _ErrorCatcher({required this.child, required this.onError});

  final Widget child;
  final void Function(FlutterErrorDetails details) onError;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        try {
          return child;
        } catch (e, st) {
          final details = FlutterErrorDetails(
            exception: e,
            stack: st,
            library: 'AppErrorBoundary',
          );
          onError(details);
          return AppGracefulErrorWidget(details: details);
        }
      },
    );
  }
}
