import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

class NotificationFeedback {
  NotificationFeedback._();

  static Widget loading() => const NotificationSkeleton();

  static Widget error(
    BuildContext context, {
    required VoidCallback onRetry,
    String? message,
  }) {
    final l10n = AppLocalizations.of(context)!;
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
            const SizedBox(height: 16),
            Text(
              message ?? l10n.notificationLoadError,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: Text(l10n.notificationRetry),
            ),
          ],
        ),
      ),
    );
  }

  static Widget empty(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_none_outlined, size: 48),
            const SizedBox(height: 16),
            Text(l10n.noNotifications, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  static Widget offlineHint(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        l10n.notificationOfflineHint,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class NotificationSkeleton extends StatelessWidget {
  const NotificationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, _) => Container(
        height: 88,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
