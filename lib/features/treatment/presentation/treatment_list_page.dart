import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import '../../animals/presentation/animal_providers.dart';
import '../data/treatment_dto.dart';
import 'treatment_providers.dart';
import 'widgets/treatment_feedback.dart';
import 'widgets/treatment_labels.dart';
import 'widgets/treatment_record_card.dart';

class TreatmentListPage extends ConsumerStatefulWidget {
  const TreatmentListPage({super.key});

  @override
  ConsumerState<TreatmentListPage> createState() => _TreatmentListPageState();
}

class _TreatmentListPageState extends ConsumerState<TreatmentListPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(treatmentProvider.notifier).loadMore();
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
    ref.read(treatmentSearchProvider.notifier).state = _searchController.text
        .trim();
    ref.read(treatmentProvider.notifier).applyQuery();
  }

  Future<void> _pickFromDate() async {
    final current = ref.read(treatmentFromDateProvider) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: ref.read(treatmentToDateProvider) ?? DateTime.now(),
    );
    if (picked != null) {
      ref.read(treatmentFromDateProvider.notifier).state = DateTime(
        picked.year,
        picked.month,
        picked.day,
      );
      setState(() {});
    }
  }

  Future<void> _pickToDate() async {
    final current = ref.read(treatmentToDateProvider) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: ref.read(treatmentFromDateProvider) ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ref.read(treatmentToDateProvider.notifier).state = DateTime(
        picked.year,
        picked.month,
        picked.day,
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final listAsync = ref.watch(treatmentProvider);
    final statusFilter = ref.watch(treatmentStatusFilterProvider);
    final animalFilter = ref.watch(treatmentAnimalFilterProvider);
    final fromDate = ref.watch(treatmentFromDateProvider);
    final toDate = ref.watch(treatmentToDateProvider);
    final animalsAsync = ref.watch(animalListProvider);
    final livestock =
        animalsAsync.value?.animals.where((a) => a.active).toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.treatmentListTitle),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.treatmentCreate),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: listAsync.when(
        loading: TreatmentFeedback.loading,
        error: (e, _) => TreatmentFeedback.error(
          context,
          message: e.toString(),
          onRetry: () =>
              ref.read(treatmentProvider.notifier).reload(forceRefresh: true),
        ),
        data: (state) {
          final filtered = applyTreatmentDateFilter(
            state.records,
            from: fromDate,
            to: toDate,
          );
          final hasFilters =
              _searchController.text.isNotEmpty ||
              statusFilter != null ||
              animalFilter != null ||
              fromDate != null ||
              toDate != null;
          if (filtered.isEmpty && !hasFilters && !state.isRefreshing) {
            return TreatmentFeedback.empty(
              context,
              onCreate: () => context.push(AppRoutes.treatmentCreate),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(treatmentProvider.notifier).refresh(),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (state.fromCache)
                  SliverToBoxAdapter(
                    child: TreatmentFeedback.offlineHint(context),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '${l10n.treatmentSummaryEntries}: ${state.total} · ${l10n.treatmentSummaryPendingSync}: ${state.pendingSyncCount}',
                    ),
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
                              '${l10n.treatmentFromDate}: ${fromDate?.toLocal().toString().split(' ').first ?? l10n.treatmentFilterAll}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _pickToDate,
                            child: Text(
                              '${l10n.treatmentToDate}: ${toDate?.toLocal().toString().split(' ').first ?? l10n.treatmentFilterAll}',
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
                        hintText: l10n.treatmentSearchHint,
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
                          labelText: l10n.treatmentAnimalLabel,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(l10n.treatmentFilterAll),
                          ),
                          ...livestock.map(
                            (a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(a.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          ref
                                  .read(treatmentAnimalFilterProvider.notifier)
                                  .state =
                              value;
                          ref.read(treatmentProvider.notifier).applyQuery();
                        },
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        FilterChip(
                          selected: statusFilter == null,
                          label: Text(l10n.treatmentFilterAll),
                          onSelected: (_) {
                            ref
                                    .read(
                                      treatmentStatusFilterProvider.notifier,
                                    )
                                    .state =
                                null;
                            ref.read(treatmentProvider.notifier).applyQuery();
                          },
                        ),
                        ...TreatmentStatus.values.map((status) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: FilterChip(
                              selected: statusFilter == status,
                              label: Text(treatmentStatusLabel(l10n, status)),
                              onSelected: (_) {
                                ref
                                        .read(
                                          treatmentStatusFilterProvider
                                              .notifier,
                                        )
                                        .state =
                                    status;
                                ref
                                    .read(treatmentProvider.notifier)
                                    .applyQuery();
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: TreatmentFeedback.noResults(context),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TreatmentRecordCard(record: filtered[index]),
                        ),
                        childCount: filtered.length,
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
