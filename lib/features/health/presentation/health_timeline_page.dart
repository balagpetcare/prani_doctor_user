import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import '../../animals/presentation/animal_providers.dart';
import '../data/health_dto.dart';
import 'health_providers.dart';
import 'widgets/health_event_card.dart';
import 'widgets/health_feedback.dart';
import 'widgets/health_labels.dart';

class HealthTimelinePage extends ConsumerStatefulWidget {
  const HealthTimelinePage({super.key});

  @override
  ConsumerState<HealthTimelinePage> createState() => _HealthTimelinePageState();
}

class _HealthTimelinePageState extends ConsumerState<HealthTimelinePage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(healthTimelineProvider.notifier).loadMore();
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
    ref.read(healthTimelineProvider.notifier).applyQuery();
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
      ref.read(healthTimelineProvider.notifier).applyQuery();
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
      ref.read(healthTimelineProvider.notifier).applyQuery();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final timelineAsync = ref.watch(healthTimelineProvider);
    final typeFilter = ref.watch(healthEventTypeFilterProvider);
    final animalFilter = ref.watch(healthAnimalFilterProvider);
    final fromDate = ref.watch(healthFromDateProvider);
    final toDate = ref.watch(healthToDateProvider);
    final animalsAsync = ref.watch(animalListProvider);
    final livestock =
        animalsAsync.value?.animals.where((a) => a.active).toList() ?? [];

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
      body: timelineAsync.when(
        loading: HealthFeedback.loading,
        error: (e, _) => HealthFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref
              .read(healthTimelineProvider.notifier)
              .reload(forceRefresh: true),
        ),
        data: (state) {
          final hasFilters =
              _searchController.text.isNotEmpty ||
              typeFilter != null ||
              animalFilter != null;
          if (state.groups.isEmpty && !hasFilters && !state.isRefreshing) {
            return HealthFeedback.empty(
              context,
              onCreate: () => context.push(AppRoutes.healthCreate),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(healthTimelineProvider.notifier).refresh(),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (state.fromCache)
                  SliverToBoxAdapter(
                    child: HealthFeedback.offlineHint(context),
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
                          ref
                              .read(healthTimelineProvider.notifier)
                              .applyQuery();
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
                            ref
                                .read(healthTimelineProvider.notifier)
                                .applyQuery();
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
                                ref
                                    .read(healthTimelineProvider.notifier)
                                    .applyQuery();
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                if (state.groups.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: HealthFeedback.noResults(context),
                  )
                else
                  for (final group in state.groups) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          group.date,
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
                            child: HealthEventCard(event: group.events[index]),
                          ),
                          childCount: group.events.length,
                        ),
                      ),
                    ),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}
