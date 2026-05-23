import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import '../../animals/presentation/animal_providers.dart';
import '../data/milk_dto.dart';
import 'milk_providers.dart';
import 'widgets/milk_entry_card.dart';
import 'widgets/milk_feedback.dart';
import 'widgets/milk_summary_section.dart';

class MilkEntryPage extends ConsumerStatefulWidget {
  const MilkEntryPage({super.key});

  @override
  ConsumerState<MilkEntryPage> createState() => _MilkEntryPageState();
}

class _MilkEntryPageState extends ConsumerState<MilkEntryPage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(milkListProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickFromDate() async {
    final current = ref.read(milkFromDateProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: ref.read(milkToDateProvider),
    );
    if (picked != null) {
      ref.read(milkFromDateProvider.notifier).state = DateTime(
        picked.year,
        picked.month,
        picked.day,
      );
      ref.read(milkListProvider.notifier).applyQuery();
    }
  }

  Future<void> _pickToDate() async {
    final current = ref.read(milkToDateProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: ref.read(milkFromDateProvider),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ref.read(milkToDateProvider.notifier).state = DateTime(
        picked.year,
        picked.month,
        picked.day,
      );
      ref.read(milkListProvider.notifier).applyQuery();
    }
  }

  void _applySearch() {
    ref.read(milkSearchProvider.notifier).state = _searchController.text.trim();
    ref.read(milkListProvider.notifier).applyLocalFilters();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final listAsync = ref.watch(milkListProvider);
    final todaySummaryAsync = ref.watch(milkTodaySummaryProvider);
    final sessionFilter = ref.watch(milkSessionFilterProvider);
    final animalFilter = ref.watch(milkAnimalFilterProvider);
    final fromDate = ref.watch(milkFromDateProvider);
    final toDate = ref.watch(milkToDateProvider);
    final cattle =
        ref
            .watch(animalListProvider)
            .value
            ?.animals
            .where(
              (a) =>
                  a.active &&
                  (a.animalType == 'CATTLE' || a.category == 'LIVESTOCK'),
            )
            .toList() ??
        [];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.milkEntryTitle),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.milkSummary),
            icon: const Icon(Icons.summarize_outlined),
            tooltip: l10n.milkSummaryTitle,
          ),
          IconButton(
            onPressed: () => context.push(AppRoutes.milkCharts),
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: l10n.milkChartsTitle,
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'milk-evening',
            onPressed: () =>
                context.push('${AppRoutes.milkCreate}?session=evening'),
            icon: const Icon(Icons.nights_stay_outlined),
            label: Text(l10n.milkSessionEvening),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'milk-morning',
            onPressed: () =>
                context.push('${AppRoutes.milkCreate}?session=morning'),
            icon: const Icon(Icons.wb_sunny_outlined),
            label: Text(l10n.milkSessionMorning),
          ),
        ],
      ),
      body: listAsync.when(
        loading: MilkFeedback.loading,
        error: (e, _) => MilkFeedback.error(
          context,
          message: e.toString(),
          onRetry: () =>
              ref.read(milkListProvider.notifier).reload(forceRefresh: true),
        ),
        data: (state) {
          if (state.records.isEmpty &&
              _searchController.text.isEmpty &&
              sessionFilter == MilkSessionFilter.all &&
              animalFilter == null) {
            return MilkFeedback.empty(
              context,
              onCreate: () => context.push(AppRoutes.milkCreate),
            );
          }

          final todayLiters = todaySummaryAsync.value?.totalLiters ?? 0;

          return RefreshIndicator(
            onRefresh: () => ref.read(milkListProvider.notifier).refresh(),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (state.fromCache)
                  SliverToBoxAdapter(child: MilkFeedback.offlineHint(context)),
                SliverToBoxAdapter(
                  child: MilkSummarySection(
                    todayLiters: todayLiters,
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
                              '${l10n.milkFromDate}: ${fromDate.toLocal().toString().split(' ').first}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _pickToDate,
                            child: Text(
                              '${l10n.milkToDate}: ${toDate.toLocal().toString().split(' ').first}',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (cattle.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonFormField<String?>(
                        initialValue: animalFilter,
                        decoration: InputDecoration(
                          labelText: l10n.milkAnimalLabel,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(l10n.milkFilterAllAnimals),
                          ),
                          ...cattle.map(
                            (a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(a.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          ref.read(milkAnimalFilterProvider.notifier).state =
                              value;
                          ref.read(milkListProvider.notifier).applyQuery();
                        },
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: l10n.milkSearchHint,
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
                      children: MilkSessionFilter.values.map((f) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: sessionFilter == f,
                            label: Text(_sessionFilterLabel(l10n, f)),
                            onSelected: (_) {
                              ref
                                      .read(milkSessionFilterProvider.notifier)
                                      .state =
                                  f;
                              ref
                                  .read(milkListProvider.notifier)
                                  .applyLocalFilters();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                if (state.records.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text(l10n.milkNoResults)),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: MilkEntryCard(record: state.records[index]),
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
    );
  }

  String _sessionFilterLabel(AppLocalizations l10n, MilkSessionFilter filter) {
    switch (filter) {
      case MilkSessionFilter.all:
        return l10n.milkFilterAllSessions;
      case MilkSessionFilter.morning:
        return l10n.milkSessionMorning;
      case MilkSessionFilter.evening:
        return l10n.milkSessionEvening;
    }
  }
}
