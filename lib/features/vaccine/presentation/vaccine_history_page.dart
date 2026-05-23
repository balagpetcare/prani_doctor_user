import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import '../../animals/presentation/animal_providers.dart';
import 'vaccine_providers.dart';
import 'widgets/vaccine_feedback.dart';
import 'widgets/vaccine_record_card.dart';

class VaccineHistoryPage extends ConsumerStatefulWidget {
  const VaccineHistoryPage({super.key});

  @override
  ConsumerState<VaccineHistoryPage> createState() => _VaccineHistoryPageState();
}

class _VaccineHistoryPageState extends ConsumerState<VaccineHistoryPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(vaccineHistoryProvider.notifier).loadMore();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final listAsync = ref.watch(vaccineHistoryProvider);
    final search = ref.watch(vaccineSearchProvider);
    final animalFilter = ref.watch(vaccineAnimalFilterProvider);
    final fromDate = ref.watch(vaccineFromDateProvider);
    final toDate = ref.watch(vaccineToDateProvider);
    final animalsAsync = ref.watch(animalListProvider);
    final livestock =
        animalsAsync.value?.animals.where((a) => a.active).toList() ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.vaccineHistoryTitle)),
      body: listAsync.when(
        loading: VaccineFeedback.loading,
        error: (e, _) => VaccineFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref
              .read(vaccineHistoryProvider.notifier)
              .reload(forceRefresh: true),
        ),
        data: (state) {
          final filtered = applyVaccineClientFilters(
            state.records,
            search: search,
            from: fromDate,
            to: toDate,
          );
          if (filtered.isEmpty &&
              search.isEmpty &&
              fromDate == null &&
              toDate == null &&
              !state.isRefreshing) {
            return VaccineFeedback.empty(
              context,
              onCreate: () => context.push(AppRoutes.vaccineCreate),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(vaccineHistoryProvider.notifier).refresh(),
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
                          ref
                              .read(vaccineHistoryProvider.notifier)
                              .applyQuery();
                        },
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
                    padding: const EdgeInsets.all(16),
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
