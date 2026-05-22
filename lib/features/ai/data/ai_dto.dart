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
  final AiMessageStatus status;
  final bool fromCache;

  bool get isFailed => status == AiMessageStatus.failed;
  bool get isPending => status == AiMessageStatus.pendingSync || status == AiMessageStatus.sending;

  AiChatMessage copyWith({
    String? id,
    AiMessageRole? role,
    String? content,
    DateTime? createdAt,
    bool? refused,
    bool? humanRedirect,
    bool? escalationRecommended,
    String? disclaimer,
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
      escalationRecommended: escalationRecommended ?? this.escalationRecommended,
      disclaimer: disclaimer ?? this.disclaimer,
      status: status ?? this.status,
      fromCache: fromCache ?? this.fromCache,
    );
  }

  factory AiChatMessage.fromJson(Map<String, dynamic> json, {bool fromCache = false}) {
    return AiChatMessage(
      id: json['id'] as String? ?? '',
      role: AiMessageRoleApi.fromApi(json['role'] as String? ?? 'SYSTEM'),
      content: json['content'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      refused: json['refused'] as bool? ?? false,
      humanRedirect: json['humanRedirect'] as bool? ?? false,
      escalationRecommended: json['escalationRecommended'] as bool? ?? false,
      disclaimer: json['disclaimer'] as String?,
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
  });

  final String sessionId;
  final String messageId;
  final String content;
  final bool refused;
  final bool humanRedirect;
  final bool escalationRecommended;
  final String disclaimer;

  factory AiChatResponse.fromJson(Map<String, dynamic> json) {
    return AiChatResponse(
      sessionId: json['sessionId'] as String? ?? '',
      messageId: json['messageId'] as String? ?? '',
      content: json['content'] as String? ?? '',
      refused: json['refused'] as bool? ?? false,
      humanRedirect: json['humanRedirect'] as bool? ?? false,
      escalationRecommended: json['escalationRecommended'] as bool? ?? false,
      disclaimer: json['disclaimer'] as String? ?? '',
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
  });

  final String triageId;
  final String possibleConcern;
  final AiRiskLevel urgency;
  final String recommendedAction;
  final String doctorSuggestion;
  final bool escalationRequired;
  final String disclaimer;

  factory TriageResultModel.fromJson(Map<String, dynamic> json, {required String symptomsSummary}) {
    final urgency = AiRiskLevelApi.fromApi(json['riskBucket'] as String? ?? 'LOW');
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
