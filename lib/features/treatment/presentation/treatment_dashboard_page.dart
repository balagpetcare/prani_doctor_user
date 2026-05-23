import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import 'treatment_providers.dart';
import 'widgets/treatment_feedback.dart';
import 'widgets/treatment_record_card.dart';
import 'widgets/treatment_summary_section.dart';

class TreatmentDashboardPage extends ConsumerWidget {
  const TreatmentDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summaryAsync = ref.watch(treatmentSummaryProvider);
    final followUpAsync = ref.watch(treatmentFollowUpProvider);

    ref.listen(treatmentFollowUpProvider, (previous, next) {
      next.whenData((items) {
        ref
            .read(treatmentFollowUpServiceProvider)
            .scheduleFollowUpReminders(
              items,
              title: l10n.treatmentFollowUpTitle,
              bodyFor: (treatment) => l10n.treatmentFollowUpBody(
                treatment.title,
                treatment.targetLabel,
              ),
            );
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.treatmentDashboardTitle),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.treatmentTimeline),
            icon: const Icon(Icons.timeline_outlined),
          ),
          IconButton(
            onPressed: () => context.push(AppRoutes.treatmentCreate),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(treatmentSummaryProvider);
          ref.invalidate(treatmentFollowUpProvider);
          ref.invalidate(treatmentProvider);
          await ref.read(treatmentSummaryProvider.future);
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
                child: TreatmentFeedback.error(
                  context,
                  onRetry: () => ref.invalidate(treatmentSummaryProvider),
                ),
              ),
              data: (summary) => Column(
                children: [
                  if (summary.fromCache)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TreatmentFeedback.offlineHint(context),
                    ),
                  TreatmentSummarySection(summary: summary),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(
                    onPressed: () => context.push(AppRoutes.treatmentCreate),
                    child: Text(l10n.treatmentAddTitle),
                  ),
                  OutlinedButton(
                    onPressed: () => context.push(AppRoutes.treatmentList),
                    child: Text(l10n.treatmentListTitle),
                  ),
                  OutlinedButton(
                    onPressed: () =>
                        context.push(AppRoutes.treatmentMedicinePlan),
                    child: Text(l10n.treatmentMedicinePlanTitle),
                  ),
                  OutlinedButton(
                    onPressed: () => context.push(AppRoutes.treatmentFollowUp),
                    child: Text(l10n.treatmentFollowUpTitle),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                l10n.treatmentFollowUpTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            followUpAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: LinearProgressIndicator(),
              ),
              error: (_, _) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(l10n.treatmentLoadError),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(l10n.treatmentNoFollowUp),
                  );
                }
                return Column(
                  children: items
                      .take(5)
                      .map(
                        (record) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: TreatmentRecordCard(record: record),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
