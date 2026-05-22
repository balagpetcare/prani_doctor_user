import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import '../data/batch_dto.dart';
import 'batch_providers.dart';
import 'widgets/batch_card.dart';
import 'widgets/batch_feedback.dart';

class BatchListPage extends ConsumerStatefulWidget {
  const BatchListPage({super.key});

  @override
  ConsumerState<BatchListPage> createState() => _BatchListPageState();
}

class _BatchListPageState extends ConsumerState<BatchListPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(batchListProvider.notifier).loadMore();
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
    ref.read(batchSearchProvider.notifier).state = _searchController.text.trim();
    ref.read(batchListProvider.notifier).applyQuery();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final listAsync = ref.watch(batchListProvider);
    final filter = ref.watch(batchFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.batchListTitle),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.batchCreate),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: listAsync.when(
        loading: () => BatchFeedback.loading(),
        error: (e, _) => BatchFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.read(batchListProvider.notifier).reload(forceRefresh: true),
        ),
        data: (state) {
          if (state.batches.isEmpty && !state.isRefreshing) {
            return BatchFeedback.empty(
              context,
              onCreate: () => context.push(AppRoutes.batchCreate),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(batchListProvider.notifier).refresh(),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                if (state.fromCache) SliverToBoxAdapter(child: BatchFeedback.offlineHint(context)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: l10n.batchSearchHint,
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
                      children: BatchFilter.values.map((f) {
                        final selected = filter == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: selected,
                            label: Text(_filterLabel(l10n, f)),
                            onSelected: (_) {
                              ref.read(batchFilterProvider.notifier).state = f;
                              ref.read(batchListProvider.notifier).applyQuery();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: BatchCard(batch: state.batches[index]),
                      ),
                      childCount: state.batches.length,
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

  String _filterLabel(AppLocalizations l10n, BatchFilter filter) {
    switch (filter) {
      case BatchFilter.all:
        return l10n.batchFilterAll;
      case BatchFilter.active:
        return l10n.batchFilterActive;
      case BatchFilter.empty:
        return l10n.batchFilterEmpty;
    }
  }
}
