import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import 'treatment_providers.dart';
import 'widgets/treatment_feedback.dart';
import 'widgets/treatment_record_card.dart';

class TreatmentTimelinePage extends ConsumerWidget {
  const TreatmentTimelinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final timelineAsync = ref.watch(treatmentTimelineProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.treatmentTimelineTitle)),
      body: timelineAsync.when(
        loading: TreatmentFeedback.loading,
        error: (e, _) => TreatmentFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.invalidate(treatmentTimelineProvider),
        ),
        data: (groups) {
          if (groups.isEmpty) {
            return TreatmentFeedback.empty(
              context,
              onCreate: () => context.push(AppRoutes.treatmentCreate),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(treatmentTimelineProvider);
              await ref.read(treatmentTimelineProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      group.month,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    ...group.records.map(
                      (record) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TreatmentRecordCard(record: record),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
