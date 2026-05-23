import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import '../notification_analytics.dart';
import 'notification_providers.dart';
import 'widgets/notification_card.dart';
import 'widgets/notification_feedback.dart';

class NotificationListPage extends ConsumerStatefulWidget {
  const NotificationListPage({super.key});

  @override
  ConsumerState<NotificationListPage> createState() =>
      _NotificationListPageState();
}

class _NotificationListPageState extends ConsumerState<NotificationListPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(notificationListProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final listAsync = ref.watch(notificationListProvider);
    final search = ref.watch(notificationSearchProvider);
    final unreadOnly = ref.watch(notificationUnreadOnlyProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            decoration: InputDecoration(
              hintText: l10n.notificationSearchHint,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) =>
                ref.read(notificationSearchProvider.notifier).state = value,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              FilterChip(
                label: Text(l10n.notificationFilterAll),
                selected: !unreadOnly,
                onSelected: (_) {
                  ref.read(notificationUnreadOnlyProvider.notifier).state =
                      false;
                  ref.invalidate(notificationListProvider);
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(l10n.notificationFilterUnread),
                selected: unreadOnly,
                onSelected: (_) {
                  ref.read(notificationUnreadOnlyProvider.notifier).state =
                      true;
                  ref.invalidate(notificationListProvider);
                },
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  NotificationAnalytics.settingsOpened();
                  context.push(AppRoutes.settingsNotifications);
                },
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: Text(l10n.notificationSettingsTitle),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () =>
                  ref.read(notificationListProvider.notifier).markAllRead(),
              child: Text(l10n.markAllRead),
            ),
          ),
        ),
        Expanded(
          child: listAsync.when(
            loading: NotificationFeedback.loading,
            error: (e, _) => NotificationFeedback.error(
              context,
              message: e.toString(),
              onRetry: () => ref
                  .read(notificationListProvider.notifier)
                  .reload(forceRefresh: true),
            ),
            data: (state) {
              final grouped = state.groupedBy(search);
              final visibleCount = grouped.fold<int>(
                0,
                (sum, section) => sum + section.items.length,
              );
              if (visibleCount == 0 && !state.isRefreshing) {
                return NotificationFeedback.empty(context);
              }
              return RefreshIndicator(
                onRefresh: () =>
                    ref.read(notificationListProvider.notifier).refresh(),
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    if (state.fromCache)
                      SliverToBoxAdapter(
                        child: NotificationFeedback.offlineHint(context),
                      ),
                    for (final section in grouped) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Text(
                            notificationGroupLabel(l10n, section.group),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: NotificationCard(
                                notification: section.items[index],
                              ),
                            ),
                            childCount: section.items.length,
                          ),
                        ),
                      ),
                    ],
                    if (state.hasMore)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
