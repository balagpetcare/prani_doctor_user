/// AI veterinary assistant DTOs — mirrors /api/ai/* foundation responses.
class AiChatResponseDto {
  const AiChatResponseDto({
    required this.sessionId,
    required this.messageId,
    required this.content,
    required this.refused,
    required this.humanRedirect,
    required this.escalationRecommended,
    required this.disclaimer,
  });

  final String sessionId;
  final String messageId;
  final String content;
  final bool refused;
  final bool humanRedirect;
  final bool escalationRecommended;
  final String disclaimer;

  factory AiChatResponseDto.fromJson(Map<String, dynamic> json) {
    return AiChatResponseDto(
      sessionId: json['sessionId'] as String,
      messageId: json['messageId'] as String,
      content: json['content'] as String,
      refused: json['refused'] as bool? ?? false,
      humanRedirect: json['humanRedirect'] as bool? ?? false,
      escalationRecommended: json['escalationRecommended'] as bool? ?? false,
      disclaimer: json['disclaimer'] as String? ?? '',
    );
  }
}

class AiTriageResponseDto {
  const AiTriageResponseDto({
    required this.triageId,
    required this.riskBucket,
    required this.urgencyLevel,
    required this.recommendation,
    required this.escalationRequired,
    this.escalationId,
    required this.disclaimer,
  });

  final String triageId;
  final String riskBucket;
  final int urgencyLevel;
  final String recommendation;
  final bool escalationRequired;
  final String? escalationId;
  final String disclaimer;

  factory AiTriageResponseDto.fromJson(Map<String, dynamic> json) {
    return AiTriageResponseDto(
      triageId: json['triageId'] as String,
      riskBucket: json['riskBucket'] as String,
      urgencyLevel: json['urgencyLevel'] as int? ?? 0,
      recommendation: json['recommendation'] as String? ?? '',
      escalationRequired: json['escalationRequired'] as bool? ?? false,
      escalationId: json['escalationId'] as String?,
      disclaimer: json['disclaimer'] as String? ?? '',
    );
  }
}

class AiMemoryEntryDto {
  const AiMemoryEntryDto({
    required this.id,
    required this.kind,
    required this.key,
    required this.value,
    this.expiresAt,
    required this.updatedAt,
  });

  final String id;
  final String kind;
  final String key;
  final dynamic value;
  final String? expiresAt;
  final String updatedAt;

  factory AiMemoryEntryDto.fromJson(Map<String, dynamic> json) {
    return AiMemoryEntryDto(
      id: json['id'] as String,
      kind: json['kind'] as String,
      key: json['key'] as String,
      value: json['value'],
      expiresAt: json['expiresAt'] as String?,
      updatedAt: json['updatedAt'] as String,
    );
  }
}

class AiEscalationDto {
  const AiEscalationDto({
    required this.id,
    required this.reason,
    required this.status,
    this.caseId,
    this.sessionId,
    this.handoffNote,
    required this.flaggedAt,
  });

  final String id;
  final String reason;
  final String status;
  final String? caseId;
  final String? sessionId;
  final String? handoffNote;
  final String flaggedAt;

  factory AiEscalationDto.fromJson(Map<String, dynamic> json) {
    return AiEscalationDto(
      id: json['id'] as String,
      reason: json['reason'] as String,
      status: json['status'] as String,
      caseId: json['caseId'] as String?,
      sessionId: json['sessionId'] as String?,
      handoffNote: json['handoffNote'] as String?,
      flaggedAt: json['flaggedAt'] as String,
    );
  }
}
