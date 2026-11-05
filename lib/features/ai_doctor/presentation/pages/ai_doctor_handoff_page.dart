import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/app_routes.dart';
import '../../../ai/presentation/compliance/ai_compliance_model.dart';
import '../../../ai/presentation/compliance/ai_compliance_shell.dart';
import '../../data/ai_doctor_dto.dart';
import '../providers/ai_doctor_providers.dart';
import '../widgets/confidence_badge.dart';
import '../widgets/differential_card.dart';
import '../widgets/risk_banner.dart';

class AiDoctorHandoffPage extends ConsumerWidget {
  const AiDoctorHandoffPage({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caseAsync = ref.watch(aiDoctorCaseProvider(caseId));
    final analysis = caseAsync.valueOrNull?.lastAnalysis;

    return Scaffold(
      appBar: AppBar(title: const Text('কেস হস্তান্তর সারাংশ')),
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

            final risk = analysis?.riskAssessment ?? aiCase.riskAssessment;
            final confidence = analysis?.confidence ?? aiCase.confidence;
            final differentials =
                analysis?.differentials ?? aiCase.differentials;
            final snapshot = aiCase.symptomSnapshot;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'ভেটের কাছে পাঠানোর আগে সারাংশ যাচাই করুন',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    title: Text(
                      apiSpeciesLabelBn(livestockSpeciesToApi(aiCase.species)),
                    ),
                    subtitle: Text('কেস ID: ${aiCase.id}'),
                  ),
                ),
                if (risk != null) ...[
                  const SizedBox(height: 12),
                  RiskBanner(risk: risk),
                ],
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'লক্ষণ',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          [
                            ...snapshot.symptomCodes,
                            ...snapshot.freeTextSymptoms,
                          ].join(', '),
                        ),
                        if (snapshot.durationDays != null)
                          Text('Duration: ${snapshot.durationDays} days'),
                        if (snapshot.severity != null)
                          Text('Severity: ${snapshot.severity!.apiValue}'),
                      ],
                    ),
                  ),
                ),
                if (confidence != null) ...[
                  const SizedBox(height: 12),
                  ConfidenceBadge(confidence: confidence),
                ],
                if (differentials.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DifferentialList(
                    differentials: differentials,
                    chunks: analysis?.pack?.chunks ?? const [],
                  ),
                ],
                if (analysis != null && analysis.content.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(analysis.content),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () =>
                      context.push(AppRoutes.aiDoctorCaseEscalate(caseId)),
                  icon: const Icon(Icons.send),
                  label: const Text('হস্তান্তর চালিয়ে যান'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
