import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import '../notification_analytics.dart';
import 'notification_providers.dart';
import 'widgets/notification_card.dart';
import 'widgets/notification_feedback.dart';
import 'widgets/notification_summary_section.dart';

class NotificationCenterPage extends ConsumerWidget {
  const NotificationCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final unreadAsync = ref.watch(unreadNotificationCountProvider);
    final listAsync = ref.watch(notificationListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationCenterTitle),
        actions: [
          IconButton(
            onPressed: () {
              NotificationAnalytics.settingsOpened();
              context.push(AppRoutes.settingsNotifications);
            },
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.notificationSettingsTitle,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(notificationListProvider.notifier).refresh();
          ref.invalidate(unreadNotificationCountProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            unreadAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: NotificationFeedback.error(
                  context,
                  onRetry: () =>
                      ref.invalidate(unreadNotificationCountProvider),
                ),
              ),
              data: (unread) => listAsync.when(
                loading: () => NotificationSummarySection(
                  unreadCount: unread,
                  totalLoaded: 0,
                ),
                error: (_, _) => NotificationSummarySection(
                  unreadCount: unread,
                  totalLoaded: 0,
                ),
                data: (state) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (state.fromCache)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: NotificationFeedback.offlineHint(context),
                      ),
                    NotificationSummarySection(
                      unreadCount: unread,
                      totalLoaded: state.items.length,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => context.go(AppRoutes.inbox),
                    icon: const Icon(Icons.inbox_outlined),
                    label: Text(l10n.notificationViewAll),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.push(AppRoutes.notificationPermission),
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: Text(l10n.notificationPermissionTitle),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                l10n.notificationRecentTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            listAsync.when(
              loading: NotificationFeedback.loading,
              error: (e, _) => NotificationFeedback.error(
                context,
                message: e.toString(),
                onRetry: () => ref
                    .read(notificationListProvider.notifier)
                    .reload(forceRefresh: true),
              ),
              data: (state) {
                if (state.items.isEmpty) {
                  return NotificationFeedback.empty(context);
                }
                final recent = state.items.take(5).toList();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      for (final item in recent)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: NotificationCard(notification: item),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
