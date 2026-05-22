import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import 'health_providers.dart';
import 'widgets/health_event_card.dart';
import 'widgets/health_feedback.dart';

class HealthTimelinePage extends ConsumerStatefulWidget {
  const HealthTimelinePage({super.key});

  @override
  ConsumerState<HealthTimelinePage> createState() => _HealthTimelinePageState();
}

class _HealthTimelinePageState extends ConsumerState<HealthTimelinePage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        ref.read(healthTimelineProvider.notifier).loadMore();
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
    final state = ref.watch(healthTimelineProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.healthTimelineTitle),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.healthCreate),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: switch (state) {
        HealthTimelineLoading() => HealthFeedback.loading(),
        HealthTimelineError(:final error) => HealthFeedback.error(
            context,
            message: error.toString(),
            onRetry: () => ref.read(healthTimelineProvider.notifier).reload(forceRefresh: true),
          ),
        HealthTimelineEmpty(:final isRefreshing) => isRefreshing
            ? HealthFeedback.loading()
            : HealthFeedback.empty(context, onCreate: () => context.push(AppRoutes.healthCreate)),
        HealthTimelineLoaded(:final data) => RefreshIndicator(
            onRefresh: () => ref.read(healthTimelineProvider.notifier).refresh(),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (data.fromCache) SliverToBoxAdapter(child: HealthFeedback.offlineHint(context)),
                for (final group in data.groups) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(group.date, style: Theme.of(context).textTheme.titleSmall),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: HealthEventCard(event: group.events[index]),
                        ),
                        childCount: group.events.length,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      },
    );
  }
}
