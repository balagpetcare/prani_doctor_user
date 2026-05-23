import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/navigation/navigation_guard.dart';

import '../../service_requests/presentation/service_request_status_chip.dart';
import '../notification_deeplink.dart';
import 'notification_navigation.dart';
import 'notification_providers.dart';
import 'widgets/notification_feedback.dart';

class NotificationDetailPage extends ConsumerWidget {
  const NotificationDetailPage({super.key, required this.notificationId});

  final String notificationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final detailAsync = ref.watch(notificationDetailProvider(notificationId));

    return Scaffold(
      appBar: safeAppBar(context, title: Text(l10n.notificationDetailTitle)),
      body: detailAsync.when(
        loading: NotificationFeedback.loading,
        error: (e, _) => NotificationFeedback.error(
          context,
          message: e.toString(),
          onRetry: () =>
              ref.invalidate(notificationDetailProvider(notificationId)),
        ),
        data: (notification) {
          if (notification == null) {
            return NotificationFeedback.error(
              context,
              message: l10n.notificationDetailNotFound,
              onRetry: () =>
                  ref.invalidate(notificationDetailProvider(notificationId)),
            );
          }

          final route = NotificationDeepLink.resolve(
            metadata: notification.metadata,
            type: notification.type,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (notification.fromCache)
                NotificationFeedback.offlineHint(context),
              Text(
                notification.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(formatTimestamp(notification.createdAt)),
              const SizedBox(height: 16),
              Text(notification.body),
              const SizedBox(height: 24),
              if (notification.isUnread)
                OutlinedButton(
                  onPressed: () async {
                    await ref
                        .read(notificationListProvider.notifier)
                        .markRead(notification.id);
                    NotificationNavigation.afterRead(ref);
                    ref.invalidate(notificationDetailProvider(notificationId));
                  },
                  child: Text(l10n.notificationMarkRead),
                ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () async {
                  if (notification.isUnread) {
                    await ref
                        .read(notificationListProvider.notifier)
                        .markRead(notification.id);
                    NotificationNavigation.afterRead(ref);
                  }
                  if (!context.mounted) return;
                  context.go(route);
                },
                child: Text(l10n.notificationOpenAction),
              ),
            ],
          );
        },
      ),
    );
  }
}
