import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../emergency_limitation/data/emergency_limitation_dto.dart';
import '../../../emergency_limitation/presentation/widgets/emergency_limitation_banner.dart';
import '../ai_disclaimer_providers.dart';
import '../widgets/ai_escalation_disclosure_strip.dart';
import 'ai_compliance_fallback.dart';
import 'ai_compliance_model.dart';

/// Ensures every AI-generated output includes limitation, disclaimer, and emergency UX.
class AiOutputComplianceWrapper extends ConsumerWidget {
  const AiOutputComplianceWrapper({
    super.key,
    required this.evaluation,
    required this.child,
    this.inlineDisclaimer,
    this.apiEscalationDisclosure,
    this.showKeywordLimitation = false,
    this.onRequestHumanReview,
  });

  final AiComplianceEvaluation evaluation;
  final Widget child;
  final String? inlineDisclaimer;
  final String? apiEscalationDisclosure;
  final bool showKeywordLimitation;
  final VoidCallback? onRequestHumanReview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(aiDisclaimerLocaleProvider);
    final disclaimerText = _resolveInlineDisclaimer(ref, locale);
    final trigger = evaluation.showEscalationStrip ? evaluation.escalationTrigger : null;

    return Semantics(
      container: true,
      liveRegion: evaluation.emergency,
      label: evaluation.emergency
          ? 'Emergency veterinary guidance required'
          : 'AI assistive output with limitations',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (evaluation.showUrgentBanner)
            EmergencyLimitationBanner(
              urgent: true,
              context: EmergencyLimitationContext.aiEmergency,
              fallback: AiComplianceFallbackCopy.emergencyForLocale(locale),
            ),
          child,
          if (disclaimerText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              disclaimerText,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (trigger != null)
            AiEscalationDisclosureStrip(
              trigger: trigger,
              apiDisclosure: apiEscalationDisclosure,
              showKeywordLimitation: showKeywordLimitation,
              onRequestHumanReview: onRequestHumanReview,
            ),
        ],
      ),
    );
  }

  String _resolveInlineDisclaimer(WidgetRef ref, String locale) {
    if (inlineDisclaimer != null && inlineDisclaimer!.trim().isNotEmpty) {
      return inlineDisclaimer!.trim();
    }
    return AiComplianceFallbackCopy.inlineDisclaimerForLocale(locale);
  }
}
