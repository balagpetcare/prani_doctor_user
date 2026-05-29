import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../routing/app_routes.dart';
import '../../data/ai_dto.dart';
import '../widgets/ai_disclaimer_banner.dart';
import '../../data/ai_disclaimer_dto.dart';
import 'ai_escalation_disclosure_strip.dart';

class TriageCard extends ConsumerWidget {
  const TriageCard({super.key, required this.result});

  final TriageResultModel result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final trigger = result.escalationFields?.trigger ??
        escalationTriggerFromTriage(
          escalationRequired: result.escalationRequired,
          emergency: result.emergency,
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.aiTriageTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _Row(label: l10n.aiPossibleConcern, value: result.possibleConcern),
            _Row(
              label: l10n.aiUrgencyLabel,
              value: _urgencyLabel(l10n, result.urgency),
            ),
            _Row(
              label: l10n.aiRecommendedAction,
              value: result.recommendedAction,
            ),
            _Row(
              label: l10n.aiDoctorSuggestion,
              value: result.doctorSuggestion,
            ),
            const SizedBox(height: 8),
            Text(
              result.disclaimer,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            const AiDisclaimerBanner(feature: AiDisclaimerFeature.advisory),
            if (trigger != null)
              AiEscalationDisclosureStrip(
                trigger: trigger,
                apiDisclosure: result.escalationFields?.disclosure,
                showKeywordLimitation: true,
                showSupportAction: true,
                showFindVetAction: true,
              )
            else if (result.escalationRequired) ...[
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () =>
                    context.push(AppRoutes.aiResult, extra: result),
                child: Text(l10n.aiViewResult),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _urgencyLabel(AppLocalizations l10n, AiRiskLevel level) {
    switch (level) {
      case AiRiskLevel.low:
        return l10n.aiUrgencyLow;
      case AiRiskLevel.medium:
        return l10n.aiUrgencyMedium;
      case AiRiskLevel.high:
        return l10n.aiUrgencyHigh;
    }
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          Text(value),
        ],
      ),
    );
  }
}
