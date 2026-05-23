import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/navigation/navigation_service.dart';
import '../../../routing/app_routes.dart';
import 'health_providers.dart';
import 'widgets/health_event_card.dart';
import 'widgets/health_feedback.dart';
import 'widgets/health_summary_section.dart';

class HealthDashboardPage extends ConsumerWidget {
  const HealthDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summaryAsync = ref.watch(healthSummaryProvider);
    final recentAsync = ref.watch(healthRecentEventsProvider);

    return NavigationBackHandler(
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.healthDashboardTitle),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: () => context.push(AppRoutes.healthAnalytics),
              icon: const Icon(Icons.insights_outlined),
              tooltip: l10n.healthAnalyticsTitle,
            ),
            IconButton(
              onPressed: () => context.push(AppRoutes.healthTimeline),
              icon: const Icon(Icons.timeline_outlined),
              tooltip: l10n.healthTimelineTitle,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(healthSummaryProvider);
            ref.invalidate(healthRecentEventsProvider);
            ref.invalidate(healthProvider);
            await ref.read(healthSummaryProvider.future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              summaryAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: HealthFeedback.error(
                    context,
                    onRetry: () => ref.invalidate(healthSummaryProvider),
                  ),
                ),
                data: (summary) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (summary.fromCache)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: HealthFeedback.offlineHint(context),
                      ),
                    HealthSummarySection(summary: summary),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () => context.push(AppRoutes.healthCreate),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.healthAddTitle),
                    ),
                    OutlinedButton(
                      onPressed: () => context.push(AppRoutes.healthHistory),
                      child: Text(l10n.healthHistoryTitle),
                    ),
                    OutlinedButton(
                      onPressed: () => context.push(AppRoutes.healthRecords),
                      child: Text(l10n.healthRecordsTitle),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  l10n.healthRecentEventsTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              recentAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: LinearProgressIndicator(),
                ),
                error: (_, _) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(l10n.healthLoadError),
                ),
                data: (events) {
                  if (events.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(l10n.healthEmpty),
                    );
                  }
                  return Column(
                    children: events
                        .map(
                          (event) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: HealthEventCard(event: event),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
