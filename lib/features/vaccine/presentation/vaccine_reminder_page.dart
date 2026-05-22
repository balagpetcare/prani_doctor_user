import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import 'vaccine_providers.dart';
import 'widgets/vaccine_feedback.dart';
import 'widgets/vaccine_record_card.dart';

class VaccineReminderPage extends ConsumerWidget {
  const VaccineReminderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final remindersAsync = ref.watch(vaccineReminderProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.vaccineRemindersTitle),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.vaccineCreate),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: remindersAsync.when(
        loading: () => VaccineFeedback.loading(),
        error: (e, _) => VaccineFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.invalidate(vaccineReminderProvider),
        ),
        data: (reminders) {
          if (reminders.overdue.isEmpty && reminders.upcoming.isEmpty) {
            return VaccineFeedback.empty(
              context,
              onCreate: () => context.push(AppRoutes.vaccineCreate),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (reminders.fromCache) VaccineFeedback.offlineHint(context),
              if (reminders.overdue.isNotEmpty) ...[
                Text(l10n.vaccineOverdueTitle, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...reminders.overdue.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: VaccineRecordCard(record: r),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (reminders.upcoming.isNotEmpty) ...[
                Text(l10n.vaccineUpcomingTitle, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...reminders.upcoming.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: VaccineRecordCard(record: r),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
