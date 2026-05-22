import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import '../data/vaccine_dto.dart';
import 'vaccine_providers.dart';
import 'widgets/vaccine_feedback.dart';
import 'widgets/vaccine_labels.dart';
import 'widgets/vaccine_record_card.dart';

class VaccineSchedulePage extends ConsumerStatefulWidget {
  const VaccineSchedulePage({super.key});

  @override
  ConsumerState<VaccineSchedulePage> createState() => _VaccineSchedulePageState();
}

class _VaccineSchedulePageState extends ConsumerState<VaccineSchedulePage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        ref.read(vaccineProvider.notifier).loadMore();
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
    final listAsync = ref.watch(vaccineProvider);
    final statusFilter = ref.watch(vaccineStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.vaccineScheduleTitle),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.vaccineReminders),
            icon: const Icon(Icons.notifications_outlined),
            tooltip: l10n.vaccineRemindersTitle,
          ),
          IconButton(
            onPressed: () => context.push(AppRoutes.vaccineCreate),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: listAsync.when(
        loading: () => VaccineFeedback.loading(),
        error: (e, _) => VaccineFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.read(vaccineProvider.notifier).reload(forceRefresh: true),
        ),
        data: (state) {
          if (state.records.isEmpty && statusFilter == null && !state.isRefreshing) {
            return VaccineFeedback.empty(
              context,
              onCreate: () => context.push(AppRoutes.vaccineCreate),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(vaccineProvider.notifier).refresh(),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (state.fromCache) SliverToBoxAdapter(child: VaccineFeedback.offlineHint(context)),
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        FilterChip(
                          selected: statusFilter == null,
                          label: Text(l10n.vaccineFilterAll),
                          onSelected: (_) {
                            ref.read(vaccineStatusFilterProvider.notifier).state = null;
                            ref.read(vaccineProvider.notifier).applyQuery();
                          },
                        ),
                        ...VaccineStatus.values.map((status) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: FilterChip(
                              selected: statusFilter == status,
                              label: Text(vaccineStatusLabel(l10n, status)),
                              onSelected: (_) {
                                ref.read(vaccineStatusFilterProvider.notifier).state = status;
                                ref.read(vaccineProvider.notifier).applyQuery();
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: VaccineRecordCard(record: state.records[index]),
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
