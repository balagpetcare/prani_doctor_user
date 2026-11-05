import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ai/data/ai_compliance_dto.dart';
import '../../../ai/presentation/compliance/ai_compliance_model.dart';
import '../../../ai/presentation/compliance/ai_output_compliance_wrapper.dart';
import '../../data/ai_doctor_dto.dart';
import 'differential_card.dart';

class AnalysisMessageCard extends ConsumerWidget {
  const AnalysisMessageCard({
    super.key,
    required this.message,
    this.onEscalate,
  });

  final AiDoctorChatMessage message;
  final VoidCallback? onEscalate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysis = message.analysis;
    final evaluation = AiComplianceEvaluation(
      emergency: analysis?.riskAssessment.emergency ?? false,
      escalationRequired: analysis?.escalationRecommended ?? message.escalationRecommended,
      riskLevel: _riskLevel(analysis?.riskAssessment.triageBucket),
      showUrgentBanner: analysis?.riskAssessment.emergency ?? false,
      showEscalationStrip:
          analysis?.escalationRecommended ?? message.escalationRecommended,
      surface: AiComplianceSurface.symptomCheck,
    );

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.92,
        ),
        child: AiOutputComplianceWrapper(
          evaluation: evaluation,
          inlineDisclaimer: message.disclaimer,
          onRequestHumanReview: onEscalate,
          child: Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(message.content),
                  if (analysis != null) ...[
                    const SizedBox(height: 12),
                    AnalysisSummaryCard(analysis: analysis),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  AiComplianceRiskLevel _riskLevel(String? bucket) {
    switch (bucket?.toUpperCase()) {
      case 'CRITICAL':
      case 'HIGH':
        return AiComplianceRiskLevel.high;
      case 'MEDIUM':
        return AiComplianceRiskLevel.medium;
      default:
        return AiComplianceRiskLevel.low;
    }
  }
}

class AiDoctorUserBubble extends StatelessWidget {
  const AiDoctorUserBubble({super.key, required this.message});

  final AiDoctorChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(message.content),
              if (message.isSending)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClarificationPanel extends StatelessWidget {
  const ClarificationPanel({
    super.key,
    required this.questions,
    required this.onAnswer,
  });

  final List<ClarificationQuestionModel> questions;
  final ValueChanged<ClarificationQuestionModel> onAnswer;

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'আরও তথ্য প্রয়োজন',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            for (final q in questions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  onPressed: () => onAnswer(q),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(q.questionBn.isNotEmpty ? q.questionBn : q.questionEn),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
