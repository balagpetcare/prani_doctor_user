import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import 'milk_providers.dart';
import 'widgets/milk_entry_card.dart';
import 'widgets/milk_feedback.dart';

class MilkEntryPage extends ConsumerStatefulWidget {
  const MilkEntryPage({super.key});

  @override
  ConsumerState<MilkEntryPage> createState() => _MilkEntryPageState();
}

class _MilkEntryPageState extends ConsumerState<MilkEntryPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(milkListProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final listAsync = ref.watch(milkListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.milkEntryTitle),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.milkSummary),
            icon: const Icon(Icons.summarize_outlined),
            tooltip: l10n.milkSummaryTitle,
          ),
          IconButton(
            onPressed: () => context.push(AppRoutes.milkCharts),
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: l10n.milkChartsTitle,
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'milk-evening',
            onPressed: () => context.push('${AppRoutes.milkCreate}?session=evening'),
            icon: const Icon(Icons.nights_stay_outlined),
            label: Text(l10n.milkSessionEvening),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'milk-morning',
            onPressed: () => context.push('${AppRoutes.milkCreate}?session=morning'),
            icon: const Icon(Icons.wb_sunny_outlined),
            label: Text(l10n.milkSessionMorning),
          ),
        ],
      ),
      body: listAsync.when(
        loading: () => MilkFeedback.loading(),
        error: (e, _) => MilkFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.read(milkListProvider.notifier).reload(forceRefresh: true),
        ),
        data: (state) {
          if (state.records.isEmpty && !state.isRefreshing) {
            return MilkFeedback.empty(
              context,
              onCreate: () => context.push(AppRoutes.milkCreate),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(milkListProvider.notifier).refresh(),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (state.fromCache) SliverToBoxAdapter(child: MilkFeedback.offlineHint(context)),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: MilkEntryCard(record: state.records[index]),
                      ),
                      childCount: state.records.length,
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
}
