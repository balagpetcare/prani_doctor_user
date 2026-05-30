import 'ai_escalation_disclosure_dto.dart';
import 'ai_compliance_dto.dart';

enum AiMessageRole { user, assistant, system }

extension AiMessageRoleApi on AiMessageRole {
  String get apiValue {
    switch (this) {
      case AiMessageRole.user:
        return 'USER';
      case AiMessageRole.assistant:
        return 'ASSISTANT';
      case AiMessageRole.system:
        return 'SYSTEM';
    }
  }

  static AiMessageRole fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'USER':
        return AiMessageRole.user;
      case 'ASSISTANT':
        return AiMessageRole.assistant;
      case 'SYSTEM':
        return AiMessageRole.system;
      default:
        return AiMessageRole.system;
    }
  }
}

enum AiLocale { bn, en }

extension AiLocaleApi on AiLocale {
  String get apiValue => name;

  static AiLocale fromApi(String? value) {
    if (value == 'en') return AiLocale.en;
    return AiLocale.bn;
  }

  String get speechLocaleId => this == AiLocale.bn ? 'bn_BD' : 'en_US';
}

enum AiRiskLevel { low, medium, high }

extension AiRiskLevelApi on AiRiskLevel {
  String get apiValue => name.toUpperCase();

  static AiRiskLevel fromApi(String value) {
    return AiRiskLevel.values.firstWhere(
      (r) => r.apiValue == value.toUpperCase(),
      orElse: () => AiRiskLevel.low,
    );
  }
}

enum AiMessageStatus { sent, sending, failed, pendingSync }

class AiChatMessage {
  const AiChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.refused = false,
    this.humanRedirect = false,
    this.escalationRecommended = false,
    this.disclaimer,
    this.escalationDisclosure,
    this.escalationTrigger,
    this.compliance,
    this.status = AiMessageStatus.sent,
    this.fromCache = false,
  });

  final String id;
  final AiMessageRole role;
  final String content;
  final DateTime createdAt;
  final bool refused;
  final bool humanRedirect;
  final bool escalationRecommended;
  final String? disclaimer;
  final String? escalationDisclosure;
  final AiEscalationDisclosureTrigger? escalationTrigger;
  final AiComplianceMetadata? compliance;
  final AiMessageStatus status;
  final bool fromCache;

  bool get isFailed => status == AiMessageStatus.failed;
  bool get isPending =>
      status == AiMessageStatus.pendingSync ||
      status == AiMessageStatus.sending;

  AiChatMessage copyWith({
    String? id,
    AiMessageRole? role,
    String? content,
    DateTime? createdAt,
    bool? refused,
    bool? humanRedirect,
    bool? escalationRecommended,
    String? disclaimer,
    String? escalationDisclosure,
    AiEscalationDisclosureTrigger? escalationTrigger,
    AiComplianceMetadata? compliance,
    AiMessageStatus? status,
    bool? fromCache,
  }) {
    return AiChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      refused: refused ?? this.refused,
      humanRedirect: humanRedirect ?? this.humanRedirect,
      escalationRecommended:
          escalationRecommended ?? this.escalationRecommended,
      disclaimer: disclaimer ?? this.disclaimer,
      escalationDisclosure: escalationDisclosure ?? this.escalationDisclosure,
      escalationTrigger: escalationTrigger ?? this.escalationTrigger,
      compliance: compliance ?? this.compliance,
      status: status ?? this.status,
      fromCache: fromCache ?? this.fromCache,
    );
  }

  factory AiChatMessage.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
  }) {
    return AiChatMessage(
      id: json['id'] as String? ?? '',
      role: AiMessageRoleApi.fromApi(json['role'] as String? ?? 'SYSTEM'),
      content: json['content'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      refused: json['refused'] as bool? ?? false,
      humanRedirect: json['humanRedirect'] as bool? ?? false,
      escalationRecommended: json['escalationRecommended'] as bool? ?? false,
      disclaimer: json['disclaimer'] as String?,
      escalationDisclosure: json['escalationDisclosure'] as String?,
      escalationTrigger: AiEscalationDisclosureTriggerApi.fromApi(
        json['escalationTrigger'] as String?,
      ),
      compliance: json['compliance'] is Map<String, dynamic>
          ? AiComplianceMetadata.fromJson(json['compliance'] as Map<String, dynamic>)
          : null,
      status: _statusFromJson(json['status'] as String?),
      fromCache: fromCache,
    );
  }

  static AiMessageStatus _statusFromJson(String? value) {
    switch (value) {
      case 'sending':
        return AiMessageStatus.sending;
      case 'failed':
        return AiMessageStatus.failed;
      case 'pendingSync':
        return AiMessageStatus.pendingSync;
      default:
        return AiMessageStatus.sent;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role.apiValue,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'refused': refused,
    'humanRedirect': humanRedirect,
    'escalationRecommended': escalationRecommended,
    if (disclaimer != null) 'disclaimer': disclaimer,
    if (escalationDisclosure != null) 'escalationDisclosure': escalationDisclosure,
    if (escalationTrigger != null) 'escalationTrigger': escalationTrigger!.name,
    'status': status.name,
  };
}

class AiChatResponse {
  const AiChatResponse({
    required this.sessionId,
    required this.messageId,
    required this.content,
    required this.refused,
    required this.humanRedirect,
    required this.escalationRecommended,
    required this.disclaimer,
    this.escalationFields,
    this.compliance,
    this.emergency = false,
  });

  final String sessionId;
  final String messageId;
  final String content;
  final bool refused;
  final bool humanRedirect;
  final bool escalationRecommended;
  final String disclaimer;
  final AiEscalationDisclosureFields? escalationFields;
  final AiComplianceMetadata? compliance;
  final bool emergency;

  factory AiChatResponse.fromJson(Map<String, dynamic> json) {
    return AiChatResponse(
      sessionId: json['sessionId'] as String? ?? '',
      messageId: json['messageId'] as String? ?? '',
      content: json['content'] as String? ?? '',
      refused: json['refused'] as bool? ?? false,
      humanRedirect: json['humanRedirect'] as bool? ?? false,
      escalationRecommended: json['escalationRecommended'] as bool? ?? false,
      disclaimer: json['disclaimer'] as String? ?? '',
      escalationFields: AiEscalationDisclosureFields.fromJson(json),
      compliance: json['compliance'] is Map<String, dynamic>
          ? AiComplianceMetadata.fromJson(json['compliance'] as Map<String, dynamic>)
          : null,
      emergency: json['emergency'] as bool? ?? false,
    );
  }
}

class AiHistoryResult {
  const AiHistoryResult({
    this.sessionId,
    this.messages = const [],
    this.fromCache = false,
  });

  final String? sessionId;
  final List<AiChatMessage> messages;
  final bool fromCache;
}

class TriageResultModel {
  const TriageResultModel({
    required this.triageId,
    required this.possibleConcern,
    required this.urgency,
    required this.recommendedAction,
    required this.doctorSuggestion,
    required this.escalationRequired,
    required this.disclaimer,
    this.urgencyLevel = 0,
    this.emergency = false,
    this.compliance,
    this.escalationFields,
  });

  final String triageId;
  final String possibleConcern;
  final AiRiskLevel urgency;
  final String recommendedAction;
  final String doctorSuggestion;
  final bool escalationRequired;
  final String disclaimer;
  final int urgencyLevel;
  final bool emergency;
  final AiComplianceMetadata? compliance;
  final AiEscalationDisclosureFields? escalationFields;

  factory TriageResultModel.fromJson(
    Map<String, dynamic> json, {
    required String symptomsSummary,
  }) {
    final urgency = AiRiskLevelApi.fromApi(
      json['riskBucket'] as String? ?? 'LOW',
    );
    final urgencyLevel = json['urgencyLevel'] as int? ?? 0;
    final emergency =
        json['emergency'] as bool? ?? urgencyLevel >= 10;
    return TriageResultModel(
      triageId: json['triageId'] as String? ?? '',
      possibleConcern: symptomsSummary,
      urgency: urgency,
      recommendedAction: json['recommendation'] as String? ?? '',
      doctorSuggestion: urgency == AiRiskLevel.high
          ? 'Consider booking a veterinarian consultation soon.'
          : 'Monitor and consult a vet if symptoms worsen.',
      escalationRequired: json['escalationRequired'] as bool? ?? false,
      disclaimer: json['disclaimer'] as String? ?? '',
      urgencyLevel: urgencyLevel,
      emergency: emergency,
      compliance: json['compliance'] is Map<String, dynamic>
          ? AiComplianceMetadata.fromJson(json['compliance'] as Map<String, dynamic>)
          : null,
      escalationFields: AiEscalationDisclosureFields.fromJson(json),
    );
  }
}

class VoiceSttResult {
  const VoiceSttResult({
    required this.sessionId,
    required this.transcriptId,
    required this.normalizedText,
    required this.confidence,
    this.retrySuggested = false,
  });

  final String sessionId;
  final String transcriptId;
  final String normalizedText;
  final double confidence;
  final bool retrySuggested;

  factory VoiceSttResult.fromJson(Map<String, dynamic> json) {
    return VoiceSttResult(
      sessionId: json['sessionId'] as String? ?? '',
      transcriptId: json['transcriptId'] as String? ?? '',
      normalizedText: json['normalizedText'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      retrySuggested: json['retrySuggested'] as bool? ?? false,
    );
  }
}

class AiSendMessageInput {
  const AiSendMessageInput({
    required this.message,
    this.sessionId,
    this.locale = AiLocale.bn,
  });

  final String message;
  final String? sessionId;
  final AiLocale locale;

  Map<String, dynamic> toJson() => {
    'message': message.trim(),
    if (sessionId != null) 'sessionId': sessionId,
    'locale': locale.apiValue,
  };
}

class AiTriageInput {
  const AiTriageInput({
    required this.symptoms,
    this.sessionId,
    this.locale = AiLocale.bn,
  });

  final List<String> symptoms;
  final String? sessionId;
  final AiLocale locale;

  Map<String, dynamic> toJson() => {
    'symptoms': symptoms,
    if (sessionId != null) 'sessionId': sessionId,
    'locale': locale.apiValue,
  };
}

class AiSettings {
  const AiSettings({
    this.locale = AiLocale.bn,
    this.showSuggestions = true,
    this.rememberConversations = true,
  });

  final AiLocale locale;
  final bool showSuggestions;
  final bool rememberConversations;

  AiSettings copyWith({
    AiLocale? locale,
    bool? showSuggestions,
    bool? rememberConversations,
  }) {
    return AiSettings(
      locale: locale ?? this.locale,
      showSuggestions: showSuggestions ?? this.showSuggestions,
      rememberConversations:
          rememberConversations ?? this.rememberConversations,
    );
  }

  Map<String, dynamic> toJson() => {
    'locale': locale.apiValue,
    'showSuggestions': showSuggestions,
    'rememberConversations': rememberConversations,
  };

  factory AiSettings.fromJson(Map<String, dynamic> json) {
    return AiSettings(
      locale: AiLocaleApi.fromApi(json['locale'] as String?),
      showSuggestions: json['showSuggestions'] as bool? ?? true,
      rememberConversations: json['rememberConversations'] as bool? ?? true,
    );
  }
}
