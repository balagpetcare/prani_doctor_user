import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import '../../animals/presentation/animal_providers.dart';
import '../data/vaccine_dto.dart';
import 'vaccine_providers.dart';
import 'widgets/vaccine_feedback.dart';
import 'widgets/vaccine_labels.dart';
import 'widgets/vaccine_record_card.dart';

class VaccineSchedulePage extends ConsumerStatefulWidget {
  const VaccineSchedulePage({super.key});

  @override
  ConsumerState<VaccineSchedulePage> createState() =>
      _VaccineSchedulePageState();
}

class _VaccineSchedulePageState extends ConsumerState<VaccineSchedulePage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(vaccineProvider.notifier).loadMore();
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
    ref.read(vaccineSearchProvider.notifier).state = _searchController.text
        .trim();
    setState(() {});
  }

  Future<void> _pickFromDate() async {
    final current = ref.read(vaccineFromDateProvider) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate:
          ref.read(vaccineToDateProvider) ??
          DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      ref.read(vaccineFromDateProvider.notifier).state = DateTime(
        picked.year,
        picked.month,
        picked.day,
      );
      setState(() {});
    }
  }

  Future<void> _pickToDate() async {
    final current = ref.read(vaccineToDateProvider) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: ref.read(vaccineFromDateProvider) ?? DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      ref.read(vaccineToDateProvider.notifier).state = DateTime(
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
    final listAsync = ref.watch(vaccineProvider);
    final statusFilter = ref.watch(vaccineStatusFilterProvider);
    final search = ref.watch(vaccineSearchProvider);
    final animalFilter = ref.watch(vaccineAnimalFilterProvider);
    final fromDate = ref.watch(vaccineFromDateProvider);
    final toDate = ref.watch(vaccineToDateProvider);
    final animalsAsync = ref.watch(animalListProvider);
    final livestock =
        animalsAsync.value?.animals.where((a) => a.active).toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.vaccineScheduleTitle),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.vaccineCalendar),
            icon: const Icon(Icons.calendar_month_outlined),
          ),
          IconButton(
            onPressed: () => context.push(AppRoutes.vaccineReminders),
            icon: const Icon(Icons.notifications_outlined),
          ),
          IconButton(
            onPressed: () => context.push(AppRoutes.vaccineCreate),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: listAsync.when(
        loading: VaccineFeedback.loading,
        error: (e, _) => VaccineFeedback.error(
          context,
          message: e.toString(),
          onRetry: () =>
              ref.read(vaccineProvider.notifier).reload(forceRefresh: true),
        ),
        data: (state) {
          final filtered = applyVaccineClientFilters(
            state.records,
            search: search,
            from: fromDate,
            to: toDate,
            excludeCompleted: statusFilter == null,
          );
          final hasFilters =
              search.isNotEmpty ||
              statusFilter != null ||
              animalFilter != null ||
              fromDate != null ||
              toDate != null;
          if (filtered.isEmpty && !hasFilters && !state.isRefreshing) {
            return VaccineFeedback.empty(
              context,
              onCreate: () => context.push(AppRoutes.vaccineCreate),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(vaccineProvider.notifier).refresh(),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (state.fromCache)
                  SliverToBoxAdapter(
                    child: VaccineFeedback.offlineHint(context),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '${l10n.vaccineSummaryEntries}: ${state.total} · ${l10n.vaccineSummaryPendingSync}: ${state.pendingSyncCount}',
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
                              '${l10n.vaccineFromDate}: ${fromDate?.toLocal().toString().split(' ').first ?? l10n.vaccineFilterAll}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _pickToDate,
                            child: Text(
                              '${l10n.vaccineToDate}: ${toDate?.toLocal().toString().split(' ').first ?? l10n.vaccineFilterAll}',
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
                        hintText: l10n.vaccineSearchHint,
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
                          labelText: l10n.vaccineAnimalLabel,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(l10n.vaccineFilterAll),
                          ),
                          ...livestock.map(
                            (a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(a.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          ref.read(vaccineAnimalFilterProvider.notifier).state =
                              value;
                          ref.read(vaccineProvider.notifier).applyQuery();
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
                          label: Text(l10n.vaccineFilterAll),
                          onSelected: (_) {
                            ref
                                    .read(vaccineStatusFilterProvider.notifier)
                                    .state =
                                null;
                            ref.read(vaccineProvider.notifier).applyQuery();
                          },
                        ),
                        ...VaccineStatus.values.map((status) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: FilterChip(
                              selected: statusFilter == status,
                              label: Text(vaccineStatusLabel(l10n, status)),
                              onSelected: (_) {
                                ref
                                        .read(
                                          vaccineStatusFilterProvider.notifier,
                                        )
                                        .state =
                                    status;
                                ref.read(vaccineProvider.notifier).applyQuery();
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
                    child: VaccineFeedback.noResults(context),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: VaccineRecordCard(record: filtered[index]),
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
