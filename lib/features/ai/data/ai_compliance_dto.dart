enum AiComplianceRiskLevel { low, medium, high }

extension AiComplianceRiskLevelApi on AiComplianceRiskLevel {
  static AiComplianceRiskLevel fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'HIGH':
        return AiComplianceRiskLevel.high;
      case 'MEDIUM':
        return AiComplianceRiskLevel.medium;
      default:
        return AiComplianceRiskLevel.low;
    }
  }
}

/// Server-driven compliance metadata (additive API field).
class AiComplianceMetadata {
  const AiComplianceMetadata({
    required this.feature,
    required this.riskLevel,
    required this.emergency,
    required this.escalationRequired,
    required this.showUrgentBanner,
    required this.showEscalationStrip,
    this.complianceVersion,
    this.disclaimerVersion,
  });

  factory AiComplianceMetadata.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const AiComplianceMetadata(
        feature: 'chat',
        riskLevel: AiComplianceRiskLevel.low,
        emergency: false,
        escalationRequired: false,
        showUrgentBanner: false,
        showEscalationStrip: false,
      );
    }
    return AiComplianceMetadata(
      feature: json['feature'] as String? ?? 'chat',
      riskLevel: AiComplianceRiskLevelApi.fromApi(json['riskLevel'] as String?),
      emergency: json['emergency'] as bool? ?? false,
      escalationRequired: json['escalationRequired'] as bool? ?? false,
      showUrgentBanner: json['showUrgentBanner'] as bool? ?? false,
      showEscalationStrip: json['showEscalationStrip'] as bool? ?? false,
      complianceVersion: json['complianceVersion'] as String?,
      disclaimerVersion: json['disclaimerVersion'] as String?,
    );
  }

  final String feature;
  final AiComplianceRiskLevel riskLevel;
  final bool emergency;
  final bool escalationRequired;
  final bool showUrgentBanner;
  final bool showEscalationStrip;
  final String? complianceVersion;
  final String? disclaimerVersion;
}
