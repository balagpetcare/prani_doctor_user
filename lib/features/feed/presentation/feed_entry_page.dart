import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import '../data/feed_dto.dart';
import 'feed_providers.dart';
import 'widgets/feed_entry_card.dart';
import 'widgets/feed_feedback.dart';

class FeedEntryPage extends ConsumerStatefulWidget {
  const FeedEntryPage({super.key});

  @override
  ConsumerState<FeedEntryPage> createState() => _FeedEntryPageState();
}

class _FeedEntryPageState extends ConsumerState<FeedEntryPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(feedListProvider.notifier).loadMore();
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
    ref.read(feedSearchProvider.notifier).state = _searchController.text.trim();
    ref.read(feedListProvider.notifier).applyQuery();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final listAsync = ref.watch(feedListProvider);
    final typeFilter = ref.watch(feedTypeFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.feedEntryTitle),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.feedCost),
            icon: const Icon(Icons.payments_outlined),
            tooltip: l10n.feedCostTitle,
          ),
          IconButton(
            onPressed: () => context.push(AppRoutes.feedCreate),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: listAsync.when(
        loading: () => FeedFeedback.loading(),
        error: (e, _) => FeedFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.read(feedListProvider.notifier).reload(forceRefresh: true),
        ),
        data: (state) {
          if (state.records.isEmpty && _searchController.text.isEmpty && typeFilter == null && !state.isRefreshing) {
            return FeedFeedback.empty(
              context,
              onCreate: () => context.push(AppRoutes.feedCreate),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(feedListProvider.notifier).refresh(),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (state.fromCache) SliverToBoxAdapter(child: FeedFeedback.offlineHint(context)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: l10n.feedSearchHint,
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
                      children: [
                        FilterChip(
                          selected: typeFilter == null,
                          label: Text(l10n.feedFilterAll),
                          onSelected: (_) {
                            ref.read(feedTypeFilterProvider.notifier).state = null;
                            ref.read(feedListProvider.notifier).applyQuery();
                          },
                        ),
                        ...FeedType.values.map((type) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: FilterChip(
                              selected: typeFilter == type,
                              label: Text(type.apiValue),
                              onSelected: (_) {
                                ref.read(feedTypeFilterProvider.notifier).state = type;
                                ref.read(feedListProvider.notifier).applyQuery();
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: FeedEntryCard(record: state.records[index]),
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
