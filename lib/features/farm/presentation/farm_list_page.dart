import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/navigation/navigation_service.dart';
import '../../../routing/app_routes.dart';
import '../data/farm_dto.dart';
import 'farm_providers.dart';
import 'widgets/farm_card.dart';
import 'widgets/farm_feedback.dart';

class FarmListPage extends ConsumerStatefulWidget {
  const FarmListPage({super.key});

  @override
  ConsumerState<FarmListPage> createState() => _FarmListPageState();
}

class _FarmListPageState extends ConsumerState<FarmListPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(farmListProvider.notifier).loadMore();
    }
  }

  void _applySearch() {
    ref.read(farmSearchProvider.notifier).state = _searchController.text.trim();
    ref.read(farmListProvider.notifier).applyQuery();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final listAsync = ref.watch(farmListProvider);
    final filter = ref.watch(farmFilterProvider);
    final sort = ref.watch(farmSortProvider);

    return NavigationBackHandler(
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.farmListTitle),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: () => context.push(AppRoutes.farmCreate),
              icon: const Icon(Icons.add),
              tooltip: l10n.farmCreateTitle,
            ),
          ],
        ),
        body: listAsync.when(
          loading: FarmFeedback.loading,
          error: (e, _) => FarmFeedback.error(
            context,
            message: e.toString(),
            onRetry: () =>
                ref.read(farmListProvider.notifier).reload(forceRefresh: true),
          ),
          data: (state) {
            if (state.farms.isEmpty &&
                state.search.isEmpty &&
                filter == FarmFilter.all) {
              return FarmFeedback.empty(
                context,
                onCreate: () => context.push(AppRoutes.farmCreate),
              );
            }

            return RefreshIndicator(
              onRefresh: () => ref.read(farmListProvider.notifier).refresh(),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (state.fromCache)
                    SliverToBoxAdapter(
                      child: FarmFeedback.offlineHint(context),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: l10n.farmSearchHint,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: _applySearch,
                          ),
                        ),
                        onSubmitted: (_) => _applySearch(),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          FilterChip(
                            label: Text(l10n.farmFilterAll),
                            selected: filter == FarmFilter.all,
                            onSelected: (_) {
                              ref.read(farmFilterProvider.notifier).state =
                                  FarmFilter.all;
                              ref.read(farmListProvider.notifier).applyQuery();
                            },
                          ),
                          FilterChip(
                            label: Text(l10n.farmFilterHasAnimals),
                            selected: filter == FarmFilter.hasAnimals,
                            onSelected: (_) {
                              ref.read(farmFilterProvider.notifier).state =
                                  FarmFilter.hasAnimals;
                              ref.read(farmListProvider.notifier).applyQuery();
                            },
                          ),
                          FilterChip(
                            label: Text(l10n.farmFilterNeedsLocation),
                            selected: filter == FarmFilter.needsLocation,
                            onSelected: (_) {
                              ref.read(farmFilterProvider.notifier).state =
                                  FarmFilter.needsLocation;
                              ref.read(farmListProvider.notifier).applyQuery();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: DropdownButtonFormField<FarmSort>(
                        initialValue: sort,
                        decoration: InputDecoration(
                          labelText: l10n.farmSortLabel,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: FarmSort.nameAsc,
                            child: Text(l10n.farmSortNameAsc),
                          ),
                          DropdownMenuItem(
                            value: FarmSort.nameDesc,
                            child: Text(l10n.farmSortNameDesc),
                          ),
                          DropdownMenuItem(
                            value: FarmSort.animalsDesc,
                            child: Text(l10n.farmSortAnimalsDesc),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          ref.read(farmSortProvider.notifier).state = value;
                          ref.read(farmListProvider.notifier).applyQuery();
                        },
                      ),
                    ),
                  ),
                  if (state.farms.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text(l10n.farmNoResults)),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList.separated(
                        itemCount: state.farms.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final farm = state.farms[index];
                          return FarmCard(
                            farm: farm,
                            onTap: () =>
                                context.push(AppRoutes.farmDetail(farm.id)),
                          );
                        },
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
}
