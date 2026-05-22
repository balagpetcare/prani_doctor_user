import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../service_requests/presentation/service_request_status_chip.dart';
import '../../notification_deeplink.dart';
import '../../data/notification_dto.dart';
import '../notification_providers.dart';

class NotificationCard extends ConsumerWidget {
  const NotificationCard({super.key, required this.notification});

  final MobileNotificationDto notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Theme.of(context).colorScheme.errorContainer,
        child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onErrorContainer),
      ),
      confirmDismiss: (_) async {
        return showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.notificationDeleteTitle),
            content: Text(l10n.notificationDeleteConfirm),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.notificationDeleteAction)),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        await ref.read(notificationListProvider.notifier).delete(notification.id);
      },
      child: Card(
        color: notification.isUnread
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.25)
            : null,
        child: ListTile(
          onTap: () => _open(context, ref),
          title: Text(notification.title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notification.body),
              const SizedBox(height: 4),
              Text(formatTimestamp(notification.createdAt)),
            ],
          ),
          trailing: notification.isUnread
              ? Semantics(
                  label: l10n.notificationUnreadLabel,
                  child: const Icon(Icons.circle, size: 10, color: Colors.blue),
                )
              : null,
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    if (notification.isUnread) {
      await ref.read(notificationListProvider.notifier).markRead(notification.id);
    }
    if (!context.mounted) return;
    final route = NotificationDeepLink.resolve(
      metadata: notification.metadata,
      type: notification.type,
    );
    context.go(route);
  }
}

String notificationGroupLabel(AppLocalizations l10n, NotificationTimeGroup group) {
  return switch (group) {
    NotificationTimeGroup.today => l10n.notificationGroupToday,
    NotificationTimeGroup.yesterday => l10n.notificationGroupYesterday,
    NotificationTimeGroup.earlier => l10n.notificationGroupEarlier,
  };
}
