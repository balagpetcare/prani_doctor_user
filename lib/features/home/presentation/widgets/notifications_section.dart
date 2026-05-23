import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../routing/app_routes.dart';
import '../../../notifications/data/notification_dto.dart';
import '../../../notifications/presentation/notification_providers.dart';
import '../home_analytics.dart';
import '../providers/home_section_providers.dart';
import '../theme/home_tokens.dart';
import 'home_card.dart';
import 'home_layout.dart';
import 'home_shimmer.dart';

class HomeNotificationsSection extends ConsumerWidget {
  const HomeNotificationsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notificationsAsync = ref.watch(homeNotificationsPreviewProvider);

    return SliverToBoxAdapter(
      child: HomeSectionScope(
        label: l10n.dashboardNotifications,
        child: Padding(
          padding: const EdgeInsets.only(top: HomeTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeSectionHeader(
                title: l10n.dashboardNotifications,
                actionLabel: l10n.homeViewAll,
                onAction: () {
                  HomeAnalytics.navigate(AppRoutes.notifications);
                  context.go(AppRoutes.notifications);
                },
              ),
              notificationsAsync.when(
                loading: () => Padding(
                  padding: HomeTokens.pageHorizontal(context),
                  child: const HomeSectionShimmer(lines: 3),
                ),
                error: (_, _) => Padding(
                  padding: HomeTokens.pageHorizontal(context),
                  child: HomeErrorRetry(
                    message: l10n.dashboardSectionError,
                    onRetry: () {
                      HomeAnalytics.sectionRetry('notifications');
                      ref
                          .read(notificationListProvider.notifier)
                          .reload(forceRefresh: true);
                    },
                  ),
                ),
                data: (state) {
                  if (state.fromCache) {
                    HomeAnalytics.sectionLoaded(
                      'notifications',
                      fromCache: true,
                    );
                  }
                  if (state.items.isEmpty) {
                    return HomeEmptyState(
                      message: l10n.dashboardNoActivity,
                      icon: Icons.notifications_none_outlined,
                      actionLabel: l10n.dashboardViewAllActivity,
                      onAction: () => context.go(AppRoutes.notifications),
                    );
                  }
                  HomeAnalytics.sectionLoaded(
                    'notifications',
                    fromCache: state.fromCache,
                  );
                  final items = state.items.take(5).toList();
                  return Padding(
                    padding: HomeTokens.pageHorizontal(context),
                    child: Column(
                      children: [
                        for (var i = 0; i < items.length; i++) ...[
                          if (i > 0) const SizedBox(height: HomeTokens.space8),
                          _NotificationPreviewTile(notification: items[i]),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: HomeTokens.space8),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationPreviewTile extends StatelessWidget {
  const _NotificationPreviewTile({required this.notification});

  final MobileNotificationDto notification;

  @override
  Widget build(BuildContext context) {
    return HomeSurfaceCard(
      onTap: () {
        HomeAnalytics.navigate(AppRoutes.notificationDetail(notification.id));
        context.push(AppRoutes.notificationDetail(notification.id));
      },
      semanticLabel: notification.title,
      padding: const EdgeInsets.symmetric(
        horizontal: HomeTokens.space12,
        vertical: 10,
      ),
      child: Row(
        children: [
          Icon(
            notification.isUnread
                ? Icons.mark_email_unread_outlined
                : Icons.mark_email_read_outlined,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  notification.body,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
