import 'package:flutter/material.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/error/app_exception.dart';

class FatteningFeedback {
  FatteningFeedback._();

  static Widget loading() {
    return const Center(child: CircularProgressIndicator());
  }

  static Widget offlineHint(BuildContext context) {
    final l10n = context.tr;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: MaterialBanner(
        content: Text(l10n.t('fatteningCachedDataHint')),
        leading: const Icon(Icons.cloud_off_outlined),
        actions: [
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
            child: Text(l10n.t('Dismiss')),
          ),
        ],
      ),
    );
  }

  static String messageFromError(BuildContext context, Object error) {
    if (error is AppException) return error.message;
    return context.tr.t('errorGeneric');
  }

  static Widget error(
    BuildContext context, {
    Object? error,
    String? message,
    required VoidCallback onRetry,
    VoidCallback? onOpenCached,
    VoidCallback? onRefresh,
  }) {
    final l10n = context.tr;
    final display = error != null
        ? messageFromError(context, error)
        : (message ?? l10n.t('errorGeneric'));
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(display, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: onRetry,
                  child: Text(l10n.feedRetry),
                ),
                if (onRefresh != null)
                  OutlinedButton(
                    onPressed: onRefresh,
                    child: Text(l10n.t('Refresh')),
                  ),
                if (onOpenCached != null)
                  TextButton(
                    onPressed: onOpenCached,
                    child: Text(l10n.t('fatteningOpenCached')),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget empty(
    BuildContext context, {
    required VoidCallback onCreate,
  }) {
    final l10n = context.tr;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.grass_outlined, size: 48),
            const SizedBox(height: 16),
            Text(l10n.t('fatteningNoBatchesYet')),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onCreate,
              child: Text(l10n.batchCreateAction),
            ),
          ],
        ),
      ),
    );
  }
}
