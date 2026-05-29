import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/user_error_mapper.dart';
import 'app_error_view.dart';
import 'app_loading_view.dart';

/// Declarative renderer for an [AsyncValue], standardizing loading/error/data.
///
/// Centralizes the repetitive `value.when(...)` pattern. Pass [onRetry] to show
/// a retry button in the default error view, or supply a custom [error] builder.
///
/// Error messages are localized via [UserErrorMapper] — never shows raw
/// `error.toString()` to end users unless [errorMessage] overrides.
class AppAsyncView<T> extends StatelessWidget {
  const AppAsyncView({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.error,
    this.onRetry,
    this.errorMessage,
    this.retryLabel,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget? loading;
  final Widget Function(Object error, StackTrace stackTrace)? error;
  final VoidCallback? onRetry;
  final String Function(Object error)? errorMessage;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => loading ?? const AppLoadingView(),
      error: (err, stack) {
        if (error != null) return error!(err, stack);
        return AppErrorView(
          message: errorMessage?.call(err) ?? UserErrorMapper.message(context, err),
          onRetry: onRetry,
          retryLabel: retryLabel,
        );
      },
    );
  }
}
