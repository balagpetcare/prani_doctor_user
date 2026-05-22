import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import '../data/animal_dto.dart';
import 'animal_providers.dart';
import 'widgets/animal_card.dart';
import 'widgets/animal_feedback.dart';

class AnimalListPage extends ConsumerStatefulWidget {
  const AnimalListPage({super.key});

  @override
  ConsumerState<AnimalListPage> createState() => _AnimalListPageState();
}

class _AnimalListPageState extends ConsumerState<AnimalListPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(animalListProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final listAsync = ref.watch(animalListProvider);
    final filter = ref.watch(animalFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.animalListTitle),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.batches),
            icon: const Icon(Icons.groups_outlined),
            tooltip: l10n.batchListTitle,
          ),
          IconButton(
            onPressed: () => context.push(AppRoutes.animalCreate),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: listAsync.when(
        loading: () => AnimalFeedback.loading(),
        error: (e, _) => AnimalFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.read(animalListProvider.notifier).reload(forceRefresh: true),
        ),
        data: (state) {
          if (state.animals.isEmpty && _searchController.text.isEmpty && filter == AnimalFilter.all) {
            return AnimalFeedback.empty(
              context,
              onCreate: () => context.push(AppRoutes.animalCreate),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(animalListProvider.notifier).refresh(),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (state.fromCache) SliverToBoxAdapter(child: AnimalFeedback.offlineHint(context)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: l10n.animalSearchHint,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () {
                            ref.read(animalSearchProvider.notifier).state =
                                _searchController.text.trim();
                            ref.read(animalListProvider.notifier).applyQuery();
                          },
                        ),
                      ),
                      onSubmitted: (_) {
                        ref.read(animalSearchProvider.notifier).state =
                            _searchController.text.trim();
                        ref.read(animalListProvider.notifier).applyQuery();
                      },
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
                          label: Text(l10n.animalFilterAll),
                          selected: filter == AnimalFilter.all,
                          onSelected: (_) {
                            ref.read(animalFilterProvider.notifier).state = AnimalFilter.all;
                            ref.read(animalListProvider.notifier).applyQuery();
                          },
                        ),
                        FilterChip(
                          label: Text(l10n.animalFilterActive),
                          selected: filter == AnimalFilter.active,
                          onSelected: (_) {
                            ref.read(animalFilterProvider.notifier).state = AnimalFilter.active;
                            ref.read(animalListProvider.notifier).applyQuery();
                          },
                        ),
                        FilterChip(
                          label: Text(l10n.animalFilterLivestock),
                          selected: filter == AnimalFilter.livestock,
                          onSelected: (_) {
                            ref.read(animalFilterProvider.notifier).state = AnimalFilter.livestock;
                            ref.read(animalListProvider.notifier).applyQuery();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (state.animals.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text(l10n.animalNoResults)),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList.separated(
                      itemCount: state.animals.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final animal = state.animals[index];
                        return AnimalCard(
                          animal: animal,
                          onTap: () => context.push(AppRoutes.animalDetail(animal.id)),
                        );
                      },
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
