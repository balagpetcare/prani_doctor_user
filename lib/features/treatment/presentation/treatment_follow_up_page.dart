import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import 'treatment_providers.dart';
import 'widgets/treatment_feedback.dart';
import 'widgets/treatment_record_card.dart';

class TreatmentFollowUpPage extends ConsumerWidget {
  const TreatmentFollowUpPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final followUpAsync = ref.watch(treatmentFollowUpProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.treatmentFollowUpTitle)),
      body: followUpAsync.when(
        loading: TreatmentFeedback.loading,
        error: (e, _) => TreatmentFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.invalidate(treatmentFollowUpProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(child: Text(l10n.treatmentNoFollowUp));
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(treatmentFollowUpProvider);
              await ref.read(treatmentFollowUpProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final record = items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TreatmentRecordCard(record: record),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () =>
                              context.push(AppRoutes.treatmentEdit(record.id)),
                          child: Text(l10n.treatmentFollowUpAction),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
