import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/navigation/navigation_service.dart';
import '../../../routing/app_routes.dart';
import '../../animals/presentation/animal_providers.dart';
import '../../batches/presentation/batch_providers.dart';
import '../data/feed_dto.dart';
import 'feed_providers.dart';
import 'widgets/feed_entry_card.dart';
import 'widgets/feed_feedback.dart';
import 'widgets/feed_summary_section.dart';

class FeedEntryPage extends ConsumerStatefulWidget {
  const FeedEntryPage({super.key});

  @override
  ConsumerState<FeedEntryPage> createState() => _FeedEntryPageState();
}

class _FeedEntryPageState extends ConsumerState<FeedEntryPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(feedListProvider.notifier).loadMore();
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
    ref.read(feedSearchProvider.notifier).state = _searchController.text.trim();
    ref.read(feedListProvider.notifier).applyQuery();
  }

  Future<void> _pickFromDate() async {
    final current = ref.read(feedFromDateProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: ref.read(feedToDateProvider),
    );
    if (picked != null) {
      ref.read(feedFromDateProvider.notifier).state = DateTime(
        picked.year,
        picked.month,
        picked.day,
      );
      ref.read(feedListProvider.notifier).applyQuery();
    }
  }

  Future<void> _pickToDate() async {
    final current = ref.read(feedToDateProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: ref.read(feedFromDateProvider),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ref.read(feedToDateProvider.notifier).state = DateTime(
        picked.year,
        picked.month,
        picked.day,
      );
      ref.read(feedListProvider.notifier).applyQuery();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final listAsync = ref.watch(feedListProvider);
    final costSummaryAsync = ref.watch(feedCostSummaryProvider);
    final typeFilter = ref.watch(feedTypeFilterProvider);
    final targetFilter = ref.watch(feedTargetFilterProvider);
    final animalFilter = ref.watch(feedAnimalFilterProvider);
    final batchFilter = ref.watch(feedBatchFilterProvider);
    final fromDate = ref.watch(feedFromDateProvider);
    final toDate = ref.watch(feedToDateProvider);
    final animals =
        ref
            .watch(animalListProvider)
            .value
            ?.animals
            .where((a) => a.active)
            .toList() ??
        [];
    final batchesAsync = ref.watch(batchOptionsProvider);

    return NavigationBackHandler(
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.feedEntryTitle),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: () => context.push(AppRoutes.feedCost),
              icon: const Icon(Icons.payments_outlined),
              tooltip: l10n.feedCostTitle,
            ),
            IconButton(
              onPressed: () => context.push(AppRoutes.feedAnalytics),
              icon: const Icon(Icons.analytics_outlined),
              tooltip: l10n.feedAnalyticsTitle,
            ),
            IconButton(
              onPressed: () => context.push(AppRoutes.feedCreate),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        body: listAsync.when(
          loading: FeedFeedback.loading,
          error: (e, _) => FeedFeedback.error(
            context,
            message: e.toString(),
            onRetry: () =>
                ref.read(feedListProvider.notifier).reload(forceRefresh: true),
          ),
          data: (state) {
            if (state.records.isEmpty &&
                _searchController.text.isEmpty &&
                typeFilter == null &&
                targetFilter == FeedTargetFilter.all &&
                animalFilter == null &&
                batchFilter == null) {
              return FeedFeedback.empty(
                context,
                onCreate: () => context.push(AppRoutes.feedCreate),
              );
            }

            final totalCost = costSummaryAsync.value?.totalCostBdt ?? 0;

            return RefreshIndicator(
              onRefresh: () => ref.read(feedListProvider.notifier).refresh(),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (state.fromCache)
                    SliverToBoxAdapter(
                      child: FeedFeedback.offlineHint(context),
                    ),
                  SliverToBoxAdapter(
                    child: FeedSummarySection(
                      totalCostBdt: totalCost,
                      entryCount: state.total,
                      pendingSyncCount: state.pendingSyncCount,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _pickFromDate,
                              child: Text(
                                '${l10n.feedFromDate}: ${fromDate.toLocal().toString().split(' ').first}',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _pickToDate,
                              child: Text(
                                '${l10n.feedToDate}: ${toDate.toLocal().toString().split(' ').first}',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: l10n.feedSearchHint,
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
                            label: Text(l10n.feedFilterAll),
                            onSelected: (_) {
                              ref.read(feedTypeFilterProvider.notifier).state =
                                  null;
                              ref.read(feedListProvider.notifier).applyQuery();
                            },
                          ),
                          ...FeedType.values.map((type) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: FilterChip(
                                selected: typeFilter == type,
                                label: Text(type.apiValue),
                                onSelected: (_) {
                                  ref
                                          .read(feedTypeFilterProvider.notifier)
                                          .state =
                                      type;
                                  ref
                                      .read(feedListProvider.notifier)
                                      .applyQuery();
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: FeedTargetFilter.values.map((f) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              selected: targetFilter == f,
                              label: Text(_targetLabel(l10n, f)),
                              onSelected: (_) {
                                ref
                                        .read(feedTargetFilterProvider.notifier)
                                        .state =
                                    f;
                                ref
                                    .read(feedListProvider.notifier)
                                    .applyTargetFilter();
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  if (animals.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: DropdownButtonFormField<String?>(
                          initialValue: animalFilter,
                          decoration: InputDecoration(
                            labelText: l10n.feedAnimalLabel,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text(l10n.feedFilterAllAnimals),
                            ),
                            ...animals.map(
                              (a) => DropdownMenuItem(
                                value: a.id,
                                child: Text(a.name),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            ref.read(feedAnimalFilterProvider.notifier).state =
                                value;
                            ref.read(feedBatchFilterProvider.notifier).state =
                                null;
                            ref.read(feedListProvider.notifier).applyQuery();
                          },
                        ),
                      ),
                    ),
                  batchesAsync.when(
                    loading: () =>
                        const SliverToBoxAdapter(child: SizedBox.shrink()),
                    error: (_, _) =>
                        const SliverToBoxAdapter(child: SizedBox.shrink()),
                    data: (batches) {
                      if (batches.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: SizedBox.shrink(),
                        );
                      }
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: DropdownButtonFormField<String?>(
                            initialValue: batchFilter,
                            decoration: InputDecoration(
                              labelText: l10n.feedGroupLabel,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: null,
                                child: Text(l10n.feedFilterAllGroups),
                              ),
                              ...batches.map(
                                (b) => DropdownMenuItem(
                                  value: b.id,
                                  child: Text(b.name),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              ref.read(feedBatchFilterProvider.notifier).state =
                                  value;
                              ref
                                      .read(feedAnimalFilterProvider.notifier)
                                      .state =
                                  null;
                              ref.read(feedListProvider.notifier).applyQuery();
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  if (state.records.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text(l10n.feedNoResults)),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: FeedEntryCard(record: state.records[index]),
                          ),
                          childCount: state.records.length,
                        ),
                      ),
                    ),
                  if (state.isRefreshing)
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
    );
  }

  String _targetLabel(AppLocalizations l10n, FeedTargetFilter filter) {
    switch (filter) {
      case FeedTargetFilter.all:
        return l10n.feedFilterAllTargets;
      case FeedTargetFilter.animal:
        return l10n.feedTargetAnimal;
      case FeedTargetFilter.group:
        return l10n.feedTargetGroup;
    }
  }
}
