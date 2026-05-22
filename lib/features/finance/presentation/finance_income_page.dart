import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import '../data/finance_dto.dart';
import 'finance_providers.dart';
import 'widgets/finance_feedback.dart';
import 'widgets/finance_labels.dart';
import 'widgets/finance_record_card.dart';

class FinanceIncomePage extends ConsumerStatefulWidget {
  const FinanceIncomePage({super.key});

  @override
  ConsumerState<FinanceIncomePage> createState() => _FinanceIncomePageState();
}

class _FinanceIncomePageState extends ConsumerState<FinanceIncomePage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        ref.read(financeIncomeListProvider.notifier).loadMore();
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
    ref.read(financeIncomeSearchProvider.notifier).state = _searchController.text.trim();
    ref.read(financeIncomeListProvider.notifier).applyQuery();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final listAsync = ref.watch(financeIncomeListProvider);
    final sourceFilter = ref.watch(financeIncomeSourceFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.financeIncomeTitle),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.financeProfit),
            icon: const Icon(Icons.insights_outlined),
            tooltip: l10n.financeProfitTitle,
          ),
          IconButton(
            onPressed: () => context.push(AppRoutes.financeIncomeCreate),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: listAsync.when(
        loading: () => FinanceFeedback.loading(),
        error: (e, _) => FinanceFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.read(financeIncomeListProvider.notifier).reload(forceRefresh: true),
        ),
        data: (state) {
          if (state.records.isEmpty &&
              _searchController.text.isEmpty &&
              sourceFilter == null &&
              !state.isRefreshing) {
            return FinanceFeedback.emptyIncome(
              context,
              onCreate: () => context.push(AppRoutes.financeIncomeCreate),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(financeIncomeListProvider.notifier).refresh(),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (state.fromCache) SliverToBoxAdapter(child: FinanceFeedback.offlineHint(context)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: l10n.financeIncomeSearchHint,
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
                          selected: sourceFilter == null,
                          label: Text(l10n.financeFilterAll),
                          onSelected: (_) {
                            ref.read(financeIncomeSourceFilterProvider.notifier).state = null;
                            ref.read(financeIncomeListProvider.notifier).applyQuery();
                          },
                        ),
                        ...IncomeSource.values.map((source) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: FilterChip(
                              selected: sourceFilter == source,
                              label: Text(incomeSourceLabel(l10n, source)),
                              onSelected: (_) {
                                ref.read(financeIncomeSourceFilterProvider.notifier).state = source;
                                ref.read(financeIncomeListProvider.notifier).applyQuery();
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
                        child: FinanceRecordCard(record: state.records[index], isExpense: false),
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
