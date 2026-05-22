import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import 'treatment_providers.dart';
import 'widgets/treatment_feedback.dart';
import 'widgets/treatment_record_card.dart';

class TreatmentListPage extends ConsumerStatefulWidget {
  const TreatmentListPage({super.key});

  @override
  ConsumerState<TreatmentListPage> createState() => _TreatmentListPageState();
}

class _TreatmentListPageState extends ConsumerState<TreatmentListPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        ref.read(treatmentProvider.notifier).loadMore();
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
    ref.read(treatmentSearchProvider.notifier).state = _searchController.text.trim();
    ref.read(treatmentProvider.notifier).applyQuery();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final listAsync = ref.watch(treatmentProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.treatmentListTitle),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.treatmentCreate),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: listAsync.when(
        loading: () => TreatmentFeedback.loading(),
        error: (e, _) => TreatmentFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.read(treatmentProvider.notifier).reload(forceRefresh: true),
        ),
        data: (state) {
          if (state.records.isEmpty && _searchController.text.isEmpty && !state.isRefreshing) {
            return TreatmentFeedback.empty(
              context,
              onCreate: () => context.push(AppRoutes.treatmentCreate),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(treatmentProvider.notifier).refresh(),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (state.fromCache) SliverToBoxAdapter(child: TreatmentFeedback.offlineHint(context)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: l10n.treatmentSearchHint,
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
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TreatmentRecordCard(record: state.records[index]),
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
