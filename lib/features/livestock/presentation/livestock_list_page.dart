import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../core/localization/translation_keys.dart';
import '../../../routing/app_routes.dart';
import '../../ecosystem/presentation/active_farm_ref_provider.dart';
import '../data/livestock_dto.dart';
import 'livestock_providers.dart';
import 'widgets/livestock_card.dart';
import 'widgets/livestock_feedback.dart';

class LivestockListPage extends ConsumerStatefulWidget {
  const LivestockListPage({super.key});

  @override
  ConsumerState<LivestockListPage> createState() => _LivestockListPageState();
}

class _LivestockListPageState extends ConsumerState<LivestockListPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(livestockListProvider.notifier).loadMore();
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
    ref.read(livestockSearchProvider.notifier).state =
        _searchController.text.trim();
    ref.read(livestockListProvider.notifier).applyQuery();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.tr;
    final farmRef = ref.watch(activeFarmRefProvider);
    final listAsync = ref.watch(livestockListProvider);
    final filter = ref.watch(livestockFilterProvider);

    if (farmRef == null || farmRef.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.t(TranslationKeys.livestockListTitle))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.t(TranslationKeys.livestockNoFarmHint)),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.push(AppRoutes.farms),
                  child: Text(l10n.t(TranslationKeys.inventoryGoToFarms)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t(TranslationKeys.livestockListTitle)),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.livestockCreate),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: listAsync.when(
        loading: LivestockFeedback.loading,
        error: (e, _) => LivestockFeedback.error(
          context,
          message: e.toString(),
          onRetry: () =>
              ref.read(livestockListProvider.notifier).reload(forceRefresh: true),
        ),
        data: (state) {
          if (state.items.isEmpty &&
              _searchController.text.isEmpty &&
              filter == LivestockFilter.all) {
            return LivestockFeedback.empty(
              context,
              onCreate: () => context.push(AppRoutes.livestockCreate),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(livestockListProvider.notifier).refresh(),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (state.fromCache)
                  SliverToBoxAdapter(child: LivestockFeedback.offlineHint(context)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: l10n.t(TranslationKeys.livestockSearchHint),
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
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: LivestockFilter.values.map((f) {
                        final selected = filter == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: selected,
                            label: Text(_filterLabel(l10n, f)),
                            onSelected: (_) {
                              ref.read(livestockFilterProvider.notifier).state =
                                  f;
                              ref
                                  .read(livestockListProvider.notifier)
                                  .applyQuery();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= state.items.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final item = state.items[index];
                      return LivestockCard(
                        profile: item,
                        onTap: () =>
                            context.push(AppRoutes.livestockDetail(item.id)),
                      );
                    },
                    childCount: state.hasMore
                        ? state.items.length + 1
                        : state.items.length,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _filterLabel(dynamic l10n, LivestockFilter filter) {
    switch (filter) {
      case LivestockFilter.active:
        return l10n.t(TranslationKeys.livestockFilterActive);
      case LivestockFilter.inactive:
        return l10n.t(TranslationKeys.livestockFilterInactive);
      case LivestockFilter.all:
        return l10n.t(TranslationKeys.livestockFilterAll);
    }
  }
}
