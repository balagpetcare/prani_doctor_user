import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import '../data/support_dto.dart';
import 'support_providers.dart';
import 'widgets/support_feedback.dart';
import 'widgets/support_ticket_card.dart';

class SupportTicketListPage extends ConsumerStatefulWidget {
  const SupportTicketListPage({super.key});

  @override
  ConsumerState<SupportTicketListPage> createState() =>
      _SupportTicketListPageState();
}

class _SupportTicketListPageState extends ConsumerState<SupportTicketListPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(supportTicketListProvider.notifier).loadMore();
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
    ref.read(supportSearchProvider.notifier).state = _searchController.text
        .trim();
    ref.read(supportTicketListProvider.notifier).applyQuery();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final listAsync = ref.watch(supportTicketListProvider);
    final statusFilter = ref.watch(supportStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.supportTicketListTitle),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.supportHelp),
            icon: const Icon(Icons.help_outline),
          ),
          IconButton(
            onPressed: () => context.push(AppRoutes.supportTicketCreate),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: listAsync.when(
        loading: SupportFeedback.loading,
        error: (e, _) => SupportFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref
              .read(supportTicketListProvider.notifier)
              .reload(forceRefresh: true),
        ),
        data: (state) {
          if (state.tickets.isEmpty &&
              _searchController.text.isEmpty &&
              statusFilter == null) {
            return SupportFeedback.empty(
              context,
              onCreate: () => context.push(AppRoutes.supportTicketCreate),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(supportTicketListProvider.notifier).refresh(),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (state.fromCache)
                  SliverToBoxAdapter(
                    child: SupportFeedback.offlineHint(context),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: l10n.supportSearchHint,
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
                          label: Text(l10n.supportFilterAll),
                          selected: statusFilter == null,
                          onSelected: (_) {
                            ref
                                    .read(supportStatusFilterProvider.notifier)
                                    .state =
                                null;
                            ref
                                .read(supportTicketListProvider.notifier)
                                .applyQuery();
                          },
                        ),
                        const SizedBox(width: 8),
                        ...SupportTicketStatus.values.map(
                          (status) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(supportStatusLabel(l10n, status)),
                              selected: statusFilter == status,
                              onSelected: (_) {
                                ref
                                        .read(
                                          supportStatusFilterProvider.notifier,
                                        )
                                        .state =
                                    status;
                                ref
                                    .read(supportTicketListProvider.notifier)
                                    .applyQuery();
                              },
                            ),
                          ),
                        ),
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
                        child: SupportTicketCard(
                          ticket: state.tickets[index],
                          onTap: () => context.push(
                            AppRoutes.supportTicketDetail(
                              state.tickets[index].id,
                            ),
                          ),
                        ),
                      ),
                      childCount: state.tickets.length,
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
