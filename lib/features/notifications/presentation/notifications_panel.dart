import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import '../../service_requests/presentation/service_request_status_chip.dart';
import '../data/notification_dto.dart';
import '../data/notification_repository.dart';

class NotificationsPanel extends ConsumerWidget {
  const NotificationsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notificationsAsync = ref.watch(notificationListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () async {
                final result =
                    await ref.read(notificationRepositoryProvider).markAllRead();
                result.when(
                  success: (_) {
                    ref.invalidate(notificationListProvider);
                    ref.invalidate(unreadNotificationCountProvider);
                  },
                  failure: (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.message)),
                      );
                    }
                  },
                );
              },
              child: Text(l10n.markAllRead),
            ),
          ),
        ),
        Expanded(
          child: notificationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (items) {
              if (items.isEmpty) {
                return Center(child: Text(l10n.noNotifications));
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(notificationListProvider);
                  ref.invalidate(unreadNotificationCountProvider);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return _NotificationCard(notification: items[index]);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  const _NotificationCard({required this.notification});

  final MobileNotificationDto notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
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
            ? const Icon(Icons.circle, size: 10, color: Colors.blue)
            : null,
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    if (notification.isUnread) {
      await ref.read(notificationRepositoryProvider).markRead(notification.id);
      ref.invalidate(notificationListProvider);
      ref.invalidate(unreadNotificationCountProvider);
    }

    final requestId = notification.serviceRequestId;
    if (requestId != null && context.mounted) {
      context.go(AppRoutes.serviceRequestDetail(requestId));
    }
  }
}
