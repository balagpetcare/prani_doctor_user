import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import 'treatment_providers.dart';
import 'widgets/treatment_feedback.dart';

class TreatmentMedicinePlanPage extends ConsumerWidget {
  const TreatmentMedicinePlanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final planAsync = ref.watch(treatmentMedicinePlanProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.treatmentMedicinePlanTitle)),
      body: planAsync.when(
        loading: TreatmentFeedback.loading,
        error: (e, _) => TreatmentFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.invalidate(treatmentMedicinePlanProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(child: Text(l10n.treatmentNoMedicines));
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(treatmentMedicinePlanProvider);
              await ref.read(treatmentMedicinePlanProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      '${item.treatment.title} · ${item.treatment.targetLabel}',
                    ),
                    subtitle: Text(
                      '${item.medicine.name} · ${item.medicine.dosage}',
                    ),
                    onTap: () => context.push(
                      AppRoutes.treatmentDetail(item.treatment.id),
                    ),
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
