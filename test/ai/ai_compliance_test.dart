import 'package:flutter_test/flutter_test.dart';

import 'package:pranidoctor_user/features/ai/data/ai_compliance_dto.dart';
import 'package:pranidoctor_user/features/ai/data/ai_dto.dart';
import 'package:pranidoctor_user/features/ai/data/ai_escalation_disclosure_dto.dart';
import 'package:pranidoctor_user/features/ai/presentation/compliance/ai_compliance_model.dart';

void main() {
  group('AiComplianceEvaluation', () {
    test('fromTriage marks emergency and escalation', () {
      final evaluation = AiComplianceEvaluation.fromTriage(
        TriageResultModel(
          triageId: 't1',
          possibleConcern: 'not breathing',
          urgency: AiRiskLevel.high,
          recommendedAction: 'Seek vet',
          doctorSuggestion: 'Book vet',
          escalationRequired: true,
          disclaimer: 'Educational only',
          emergency: true,
        ),
      );
      expect(evaluation.emergency, isTrue);
      expect(evaluation.showUrgentBanner, isTrue);
      expect(evaluation.showEscalationStrip, isTrue);
      expect(evaluation.escalationTrigger, AiEscalationDisclosureTrigger.emergency);
    });

    test('fromChatMessage uses compliance metadata emergency', () {
      final evaluation = AiComplianceEvaluation.fromChatMessage(
        AiChatMessage(
          id: 'm1',
          role: AiMessageRole.assistant,
          content: 'Please seek care',
          createdAt: DateTime.now(),
          compliance: const AiComplianceMetadata(
            feature: 'chat',
            riskLevel: AiComplianceRiskLevel.high,
            emergency: true,
            escalationRequired: true,
            showUrgentBanner: true,
            showEscalationStrip: true,
          ),
        ),
      );
      expect(evaluation.emergency, isTrue);
      expect(evaluation.escalationTrigger, AiEscalationDisclosureTrigger.emergency);
    });

    test('TriageResultModel parses explicit emergency field', () {
      final triage = TriageResultModel.fromJson(
        {
          'triageId': 't2',
          'riskBucket': 'HIGH',
          'urgencyLevel': 10,
          'emergency': true,
          'recommendation': 'Emergency',
          'escalationRequired': true,
          'disclaimer': 'Note',
        },
        symptomsSummary: 'collapse',
      );
      expect(triage.emergency, isTrue);
    });
  });
}
