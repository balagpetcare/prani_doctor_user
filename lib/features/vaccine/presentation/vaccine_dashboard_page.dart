import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/navigation/navigation_service.dart';
import '../../../routing/app_routes.dart';
import 'vaccine_providers.dart';
import 'widgets/vaccine_feedback.dart';
import 'widgets/vaccine_record_card.dart';
import 'widgets/vaccine_summary_section.dart';

class VaccineDashboardPage extends ConsumerWidget {
  const VaccineDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summaryAsync = ref.watch(vaccineSummaryProvider);
    final remindersAsync = ref.watch(vaccineReminderProvider);

    ref.listen(vaccineReminderProvider, (previous, next) {
      next.whenData((reminders) {
        ref
            .read(vaccineReminderServiceProvider)
            .scheduleFallbackNotifications(
              reminders,
              overdueTitle: l10n.vaccineOverdueTitle,
              dueTitle: l10n.vaccineStatusDue,
              bodyFor: (record) => l10n.vaccineReminderBody(
                record.targetLabel,
                record.vaccineName,
              ),
            );
      });
    });

    return NavigationBackHandler(
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.vaccineDashboardTitle),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: () => context.push(AppRoutes.vaccineCalendar),
              icon: const Icon(Icons.calendar_month_outlined),
              tooltip: l10n.vaccineCalendarTitle,
            ),
            IconButton(
              onPressed: () => context.push(AppRoutes.vaccineReminders),
              icon: const Icon(Icons.notifications_outlined),
              tooltip: l10n.vaccineRemindersTitle,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(vaccineSummaryProvider);
            ref.invalidate(vaccineReminderProvider);
            ref.invalidate(vaccineProvider);
            await ref.read(vaccineSummaryProvider.future);
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
                  child: VaccineFeedback.error(
                    context,
                    onRetry: () => ref.invalidate(vaccineSummaryProvider),
                  ),
                ),
                data: (summary) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (summary.fromCache)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: VaccineFeedback.offlineHint(context),
                      ),
                    VaccineSummarySection(summary: summary),
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
                      onPressed: () => context.push(AppRoutes.vaccineCreate),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.vaccineAddTitle),
                    ),
                    OutlinedButton(
                      onPressed: () => context.push(AppRoutes.vaccineSchedule),
                      child: Text(l10n.vaccineScheduleTitle),
                    ),
                    OutlinedButton(
                      onPressed: () => context.push(AppRoutes.vaccineHistory),
                      child: Text(l10n.vaccineHistoryTitle),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  l10n.vaccineUpcomingTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              remindersAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: LinearProgressIndicator(),
                ),
                error: (_, _) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(l10n.vaccineLoadError),
                ),
                data: (reminders) {
                  final items = [
                    ...reminders.overdue,
                    ...reminders.upcoming,
                  ].take(5).toList();
                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(l10n.vaccineEmpty),
                    );
                  }
                  return Column(
                    children: items
                        .map(
                          (record) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: VaccineRecordCard(record: record),
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
