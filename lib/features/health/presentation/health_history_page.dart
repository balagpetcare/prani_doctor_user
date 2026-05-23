import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/navigation/navigation_guard.dart';
import '../../../routing/app_routes.dart';
import '../../animals/presentation/animal_providers.dart';
import '../data/health_dto.dart';
import 'health_providers.dart';
import 'widgets/health_event_card.dart';
import 'widgets/health_feedback.dart';
import 'widgets/health_labels.dart';
import 'widgets/health_summary_section.dart';

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
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
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
    ref.read(healthSearchProvider.notifier).state = _searchController.text
        .trim();
    ref.read(healthProvider.notifier).applyQuery();
  }

  Future<void> _pickFromDate() async {
    final current = ref.read(healthFromDateProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: ref.read(healthToDateProvider),
    );
    if (picked != null) {
      ref.read(healthFromDateProvider.notifier).state = DateTime(
        picked.year,
        picked.month,
        picked.day,
      );
      ref.read(healthProvider.notifier).applyQuery();
      ref.invalidate(healthSummaryProvider);
    }
  }

  Future<void> _pickToDate() async {
    final current = ref.read(healthToDateProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: ref.read(healthFromDateProvider),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ref.read(healthToDateProvider.notifier).state = DateTime(
        picked.year,
        picked.month,
        picked.day,
      );
      ref.read(healthProvider.notifier).applyQuery();
      ref.invalidate(healthSummaryProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final listAsync = ref.watch(healthProvider);
    final summaryAsync = ref.watch(healthSummaryProvider);
    final typeFilter = ref.watch(healthEventTypeFilterProvider);
    final animalFilter = ref.watch(healthAnimalFilterProvider);
    final fromDate = ref.watch(healthFromDateProvider);
    final toDate = ref.watch(healthToDateProvider);
    final animalsAsync = ref.watch(animalListProvider);
    final livestock =
        animalsAsync.value?.animals.where((a) => a.active).toList() ?? [];

    return Scaffold(
      appBar: safeAppBar(
        context,
        title: Text(l10n.healthHistoryTitle),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.healthAnalytics),
            icon: const Icon(Icons.insights_outlined),
            tooltip: l10n.healthAnalyticsTitle,
          ),
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
      body: listAsync.when(
        loading: HealthFeedback.loading,
        error: (e, _) => HealthFeedback.error(
          context,
          message: e.toString(),
          onRetry: () =>
              ref.read(healthProvider.notifier).reload(forceRefresh: true),
        ),
        data: (state) {
          final hasFilters =
              _searchController.text.isNotEmpty ||
              typeFilter != null ||
              animalFilter != null;
          if (state.records.isEmpty && !hasFilters && !state.isRefreshing) {
            return HealthFeedback.empty(
              context,
              onCreate: () => context.push(AppRoutes.healthCreate),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(healthProvider.notifier).refresh(),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (state.fromCache)
                  SliverToBoxAdapter(
                    child: HealthFeedback.offlineHint(context),
                  ),
                SliverToBoxAdapter(
                  child: summaryAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (summary) => HealthSummarySection(summary: summary),
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
                              '${l10n.healthFromDate}: ${fromDate.toLocal().toString().split(' ').first}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _pickToDate,
                            child: Text(
                              '${l10n.healthToDate}: ${toDate.toLocal().toString().split(' ').first}',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '${l10n.healthSummaryEntries}: ${state.total} · ${l10n.healthSummaryPendingSync}: ${state.pendingSyncCount}',
                    ),
                  ),
                ),
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
                if (livestock.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonFormField<String?>(
                        initialValue: animalFilter,
                        decoration: InputDecoration(
                          labelText: l10n.healthAnimalLabel,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(l10n.healthFilterAll),
                          ),
                          ...livestock.map(
                            (a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(a.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          ref.read(healthAnimalFilterProvider.notifier).state =
                              value;
                          ref.read(healthProvider.notifier).applyQuery();
                          ref.invalidate(healthSummaryProvider);
                        },
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        FilterChip(
                          selected: typeFilter == null,
                          label: Text(l10n.healthFilterAll),
                          onSelected: (_) {
                            ref
                                    .read(
                                      healthEventTypeFilterProvider.notifier,
                                    )
                                    .state =
                                null;
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
                                ref
                                        .read(
                                          healthEventTypeFilterProvider
                                              .notifier,
                                        )
                                        .state =
                                    type;
                                ref.read(healthProvider.notifier).applyQuery();
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                if (state.records.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: HealthFeedback.noResults(context),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: HealthEventCard(event: state.records[index]),
                        ),
                        childCount: state.records.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
