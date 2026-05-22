import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import '../data/health_dto.dart';
import 'health_providers.dart';
import 'widgets/health_event_card.dart';
import 'widgets/health_feedback.dart';
import 'widgets/health_labels.dart';

class HealthHistoryPage extends ConsumerStatefulWidget {
  const HealthHistoryPage({super.key});

  @override
  ConsumerState<HealthHistoryPage> createState() => _HealthHistoryPageState();
}

class _HealthHistoryPageState extends ConsumerState<HealthHistoryPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        ref.read(healthProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _applySearch() {
    ref.read(healthSearchProvider.notifier).state = _searchController.text.trim();
    ref.read(healthProvider.notifier).applyQuery();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(healthProvider);
    final typeFilter = ref.watch(healthEventTypeFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.healthHistoryTitle),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.healthTimeline),
            icon: const Icon(Icons.timeline_outlined),
            tooltip: l10n.healthTimelineTitle,
          ),
          IconButton(
            onPressed: () => context.push(AppRoutes.healthCreate),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: switch (state) {
        HealthLoading() => HealthFeedback.loading(),
        HealthError(:final error) => HealthFeedback.error(
            context,
            message: error.toString(),
            onRetry: () => ref.read(healthProvider.notifier).reload(forceRefresh: true),
          ),
        HealthEmpty(:final isRefreshing) => isRefreshing
            ? HealthFeedback.loading()
            : HealthFeedback.empty(context, onCreate: () => context.push(AppRoutes.healthCreate)),
        HealthLoaded(:final data) => RefreshIndicator(
            onRefresh: () => ref.read(healthProvider.notifier).refresh(),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (data.fromCache) SliverToBoxAdapter(child: HealthFeedback.offlineHint(context)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: l10n.healthSearchHint,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          onPressed: _applySearch,
                          icon: const Icon(Icons.arrow_forward),
                        ),
                      ),
                      onSubmitted: (_) => _applySearch(),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        FilterChip(
                          selected: typeFilter == null,
                          label: Text(l10n.healthFilterAll),
                          onSelected: (_) {
                            ref.read(healthEventTypeFilterProvider.notifier).state = null;
                            ref.read(healthProvider.notifier).applyQuery();
                          },
                        ),
                        ...HealthEventType.values.map((type) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: FilterChip(
                              selected: typeFilter == type,
                              label: Text(healthEventTypeLabel(l10n, type)),
                              onSelected: (_) {
                                ref.read(healthEventTypeFilterProvider.notifier).state = type;
                                ref.read(healthProvider.notifier).applyQuery();
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: HealthEventCard(event: data.records[index]),
                      ),
                      childCount: data.records.length,
                    ),
                  ),
                ),
              ],
            ),
          ),
      },
    );
  }
}
