import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../theme/app_spacing.dart';

/// Standard error state: icon + message + optional retry action.
///
/// Replaces the duplicated `error(...)` builders in the per-feature
/// `*_feedback.dart` helpers. Copy is passed in by the caller so each feature
/// keeps its own localized strings.
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel,
    this.icon = Icons.error_outline,
  });

  final String message;
  final VoidCallback? onRetry;

  /// Override the retry button label. Defaults to the localized "Retry" string.
  final String? retryLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: scheme.error),
            Gap.h16,
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              Gap.h16,
              FilledButton(
                onPressed: onRetry,
                child: Text(
                  retryLabel ??
                      l10n.translate(TranslationKeys.retryLabel),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
