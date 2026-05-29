import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../core/errors/user_error_mapper.dart';
import '../../core/logging/app_logger.dart';
import '../../core/navigation/safe_navigation.dart';
import '../theme/app_spacing.dart';
import 'app_error_view.dart';

/// Fallback widget shown by [ErrorWidget.builder] when a subtree fails to build.
///
/// In release mode only a friendly message is shown; debug builds include the
/// exception summary for developers.
class AppGracefulErrorWidget extends StatelessWidget {
  const AppGracefulErrorWidget({
    super.key,
    required this.details,
    this.onRetry,
  });

  final FlutterErrorDetails details;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final message = l10n?.errorGeneric ?? 'Something went wrong';
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_outlined, size: 48, color: scheme.error),
              Gap.h16,
              Text(message, textAlign: TextAlign.center),
              if (kDebugMode) ...[
                Gap.h12,
                Text(
                  details.exceptionAsString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (onRetry != null) ...[
                Gap.h16,
                FilledButton(
                  onPressed: onRetry,
                  child: Text(
                    l10n?.translate('retryLabel') ?? 'Retry',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen fallback for invalid routes or navigation failures.
class AppRouteErrorPage extends StatelessWidget {
  const AppRouteErrorPage({
    super.key,
    this.error,
    this.onGoHome,
  });

  final Exception? error;
  final VoidCallback? onGoHome;

  @override
  Widget build(BuildContext context) {
    AppLog.warn(
      'Route error page shown',
      tag: 'Nav',
      error: error,
    );

    final message = error != null
        ? UserErrorMapper.message(context, error!)
        : AppLocalizations.of(context)?.errorGeneric ?? 'Something went wrong';

    return Scaffold(
      body: AppErrorView(
        message: message,
        onRetry: onGoHome ?? () => SafeNavigation.go(context, '/'),
      ),
    );
  }
}
