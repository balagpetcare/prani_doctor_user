import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/app_routes.dart';
import '../../../ai/data/ai_compliance_dto.dart';
import '../../../ai/presentation/compliance/ai_compliance_model.dart';
import '../../../ai/presentation/compliance/ai_compliance_shell.dart';
import '../../../ai/presentation/compliance/ai_output_compliance_wrapper.dart';
import '../providers/ai_doctor_providers.dart';
import '../widgets/confidence_badge.dart';
import '../widgets/differential_card.dart';
import '../widgets/risk_banner.dart';

class AiDoctorResultPage extends ConsumerWidget {
  const AiDoctorResultPage({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caseAsync = ref.watch(aiDoctorCaseProvider(caseId));
    final analysis = caseAsync.valueOrNull?.lastAnalysis;

    return Scaffold(
      appBar: AppBar(
        title: const Text('বিশ্লেষণ ফলাফল'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_outlined),
            onPressed: () => context.push(AppRoutes.aiDoctorCaseChat(caseId)),
          ),
        ],
      ),
      body: AiCompliancePageBody(
        surface: AiComplianceSurface.symptomCheck,
        showEscalationAwarenessBanner: true,
        child: caseAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (viewState) {
            final aiCase = viewState.aiCase;
            if (aiCase == null) {
              return const Center(child: Text('কেস লোড ব্যর্থ'));
            }

            final result = analysis;
            final risk = result?.riskAssessment ?? aiCase.riskAssessment;
            final confidence = result?.confidence ?? aiCase.confidence;
            final differentials =
                result?.differentials ?? aiCase.differentials;
            final chunks = result?.pack?.chunks ?? const [];

            final evaluation = AiComplianceEvaluation(
              emergency: risk?.emergency ?? false,
              escalationRequired: result?.escalationRecommended ?? false,
              riskLevel: AiComplianceRiskLevel.medium,
              showUrgentBanner: risk?.emergency ?? false,
              showEscalationStrip: result?.escalationRecommended ?? false,
              surface: AiComplianceSurface.symptomCheck,
            );

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (risk != null) ...[
                  RiskBanner(risk: risk),
                  const SizedBox(height: 12),
                ],
                AiOutputComplianceWrapper(
                  evaluation: evaluation,
                  inlineDisclaimer: result?.disclaimer,
                  onRequestHumanReview: () =>
                      context.push(AppRoutes.aiDoctorCaseHandoff(caseId)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (result != null && result.content.isNotEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(result.content),
                          ),
                        ),
                      if (confidence != null) ...[
                        const SizedBox(height: 12),
                        ConfidenceBadge(confidence: confidence),
                      ],
                      const SizedBox(height: 12),
                      DifferentialList(
                        differentials: differentials,
                        chunks: chunks,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      context.push(AppRoutes.aiDoctorCaseHandoff(caseId)),
                  icon: const Icon(Icons.support_agent),
                  label: const Text('ভেটের কাছে হস্তান্তর'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
