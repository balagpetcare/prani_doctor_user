import '../../data/ai_compliance_dto.dart';
import '../../data/ai_disclaimer_dto.dart';
import '../../data/ai_dto.dart';
import '../../data/ai_escalation_disclosure_dto.dart';
import '../../data/ai_phase8_dto.dart';

AiEscalationDisclosureTrigger? _triageEscalationTrigger({
  required bool escalationRequired,
  required bool emergency,
}) {
  if (!escalationRequired) return null;
  return emergency ? AiEscalationDisclosureTrigger.emergency : AiEscalationDisclosureTrigger.high;
}

AiEscalationDisclosureTrigger? _chatEscalationTrigger({
  required bool refused,
  required bool escalationRecommended,
  required bool humanRedirect,
}) {
  if (refused) return AiEscalationDisclosureTrigger.policyRefusal;
  if (escalationRecommended) return AiEscalationDisclosureTrigger.lowConfidence;
  if (humanRedirect) return AiEscalationDisclosureTrigger.humanReview;
  return null;
}

enum AiComplianceSurface {
  chat,
  triage,
  symptomCheck,
  recommendations,
  farmHealth,
  knowledge,
  alerts,
  followUps,
  voice,
}

/// Client-side compliance evaluation before rendering AI output.
class AiComplianceEvaluation {
  const AiComplianceEvaluation({
    required this.emergency,
    required this.escalationRequired,
    required this.riskLevel,
    this.escalationTrigger,
    required this.showUrgentBanner,
    required this.showEscalationStrip,
    required this.surface,
  });

  final bool emergency;
  final bool escalationRequired;
  final AiComplianceRiskLevel riskLevel;
  final AiEscalationDisclosureTrigger? escalationTrigger;
  final bool showUrgentBanner;
  final bool showEscalationStrip;
  final AiComplianceSurface surface;

  static AiComplianceEvaluation fromTriage(TriageResultModel result) {
    final trigger = result.escalationFields?.trigger ??
        _triageEscalationTrigger(
          escalationRequired: result.escalationRequired,
          emergency: result.emergency,
        );
    return AiComplianceEvaluation(
      emergency: result.emergency,
      escalationRequired: result.escalationRequired,
      riskLevel: _riskFromLevel(result.urgency),
      escalationTrigger: trigger,
      showUrgentBanner: result.emergency,
      showEscalationStrip: result.escalationRequired,
      surface: AiComplianceSurface.triage,
    );
  }

  static AiComplianceEvaluation fromSymptomCheck(SymptomCheckResultModel result) {
    final trigger = result.escalationFields?.trigger ??
        (result.emergency
            ? AiEscalationDisclosureTrigger.emergency
            : result.escalationRequired
            ? AiEscalationDisclosureTrigger.high
            : null);
    return AiComplianceEvaluation(
      emergency: result.emergency,
      escalationRequired: result.escalationRequired,
      riskLevel: _riskFromBucket(result.triageBucket),
      escalationTrigger: trigger,
      showUrgentBanner: result.emergency,
      showEscalationStrip: result.escalationRequired,
      surface: AiComplianceSurface.symptomCheck,
    );
  }

  static AiComplianceEvaluation fromChatMessage(AiChatMessage message) {
    final emergency =
        message.compliance?.emergency == true ||
        message.escalationTrigger == AiEscalationDisclosureTrigger.emergency;
    final trigger = emergency
        ? AiEscalationDisclosureTrigger.emergency
        : message.escalationTrigger ??
            _chatEscalationTrigger(
              refused: message.refused,
              escalationRecommended: message.escalationRecommended,
              humanRedirect: message.humanRedirect,
            );
    final escalationRequired =
        message.compliance?.escalationRequired == true ||
        message.escalationRecommended ||
        message.humanRedirect ||
        emergency;
    return AiComplianceEvaluation(
      emergency: emergency,
      escalationRequired: escalationRequired,
      riskLevel: message.compliance?.riskLevel ??
          (escalationRequired ? AiComplianceRiskLevel.medium : AiComplianceRiskLevel.low),
      escalationTrigger: trigger,
      showUrgentBanner: emergency,
      showEscalationStrip: escalationRequired && trigger != null,
      surface: AiComplianceSurface.chat,
    );
  }

  static AiComplianceEvaluation advisory({
    required AiComplianceSurface surface,
    AiComplianceMetadata? compliance,
  }) {
    return AiComplianceEvaluation(
      emergency: compliance?.emergency ?? false,
      escalationRequired: compliance?.escalationRequired ?? false,
      riskLevel: compliance?.riskLevel ?? AiComplianceRiskLevel.low,
      escalationTrigger: (compliance?.escalationRequired ?? false)
          ? AiEscalationDisclosureTrigger.high
          : null,
      showUrgentBanner: compliance?.showUrgentBanner ?? false,
      showEscalationStrip: compliance?.showEscalationStrip ?? false,
      surface: surface,
    );
  }

  static AiComplianceRiskLevel _riskFromLevel(AiRiskLevel level) => switch (level) {
    AiRiskLevel.high => AiComplianceRiskLevel.high,
    AiRiskLevel.medium => AiComplianceRiskLevel.medium,
    AiRiskLevel.low => AiComplianceRiskLevel.low,
  };

  static AiComplianceRiskLevel _riskFromBucket(String bucket) {
    switch (bucket.toUpperCase()) {
      case 'HIGH':
        return AiComplianceRiskLevel.high;
      case 'MEDIUM':
        return AiComplianceRiskLevel.medium;
      default:
        return AiComplianceRiskLevel.low;
    }
  }
}

AiDisclaimerFeature disclaimerFeatureForSurface(AiComplianceSurface surface) =>
    switch (surface) {
      AiComplianceSurface.chat || AiComplianceSurface.voice => AiDisclaimerFeature.chat,
      AiComplianceSurface.recommendations => AiDisclaimerFeature.recommendations,
      _ => AiDisclaimerFeature.advisory,
    };
