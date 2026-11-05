import '../../ai/data/ai_dto.dart';

/// Public API species labels accepted by `/api/ai/doctor/cases`.
const aiDoctorApiSpecies = [
  'CATTLE',
  'BUFFALO',
  'GOAT',
  'SHEEP',
  'POULTRY',
  'DUCK',
  'PIGEON',
  'OTHER',
];

String livestockSpeciesToApi(String species) {
  switch (species.toUpperCase()) {
    case 'COW':
      return 'CATTLE';
    case 'CHICKEN':
      return 'POULTRY';
    default:
      final upper = species.toUpperCase();
      if (aiDoctorApiSpecies.contains(upper)) return upper;
      return 'OTHER';
  }
}

String apiSpeciesLabelBn(String species) {
  switch (species) {
    case 'CATTLE':
      return 'গরু';
    case 'BUFFALO':
      return 'মহিষ';
    case 'GOAT':
      return 'ছাগল';
    case 'SHEEP':
      return 'ভেড়া';
    case 'POULTRY':
      return 'মুরগি';
    case 'DUCK':
      return 'হাঁস';
    case 'PIGEON':
      return 'কবুতর';
    default:
      return 'অন্যান্য';
  }
}

enum AiDoctorCaseStateEnum {
  created,
  intake,
  awaitingClarification,
  emergencyTriage,
  analyzing,
  responseDelivered,
  blocked,
  escalated,
  closed,
}

extension AiDoctorCaseStateApi on AiDoctorCaseStateEnum {
  static AiDoctorCaseStateEnum fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'CREATED':
        return AiDoctorCaseStateEnum.created;
      case 'INTAKE':
        return AiDoctorCaseStateEnum.intake;
      case 'AWAITING_CLARIFICATION':
        return AiDoctorCaseStateEnum.awaitingClarification;
      case 'EMERGENCY_TRIAGE':
        return AiDoctorCaseStateEnum.emergencyTriage;
      case 'ANALYZING':
        return AiDoctorCaseStateEnum.analyzing;
      case 'RESPONSE_DELIVERED':
        return AiDoctorCaseStateEnum.responseDelivered;
      case 'BLOCKED':
        return AiDoctorCaseStateEnum.blocked;
      case 'ESCALATED':
        return AiDoctorCaseStateEnum.escalated;
      case 'CLOSED':
        return AiDoctorCaseStateEnum.closed;
      default:
        return AiDoctorCaseStateEnum.created;
    }
  }

  String get apiValue {
    switch (this) {
      case AiDoctorCaseStateEnum.created:
        return 'CREATED';
      case AiDoctorCaseStateEnum.intake:
        return 'INTAKE';
      case AiDoctorCaseStateEnum.awaitingClarification:
        return 'AWAITING_CLARIFICATION';
      case AiDoctorCaseStateEnum.emergencyTriage:
        return 'EMERGENCY_TRIAGE';
      case AiDoctorCaseStateEnum.analyzing:
        return 'ANALYZING';
      case AiDoctorCaseStateEnum.responseDelivered:
        return 'RESPONSE_DELIVERED';
      case AiDoctorCaseStateEnum.blocked:
        return 'BLOCKED';
      case AiDoctorCaseStateEnum.escalated:
        return 'ESCALATED';
      case AiDoctorCaseStateEnum.closed:
        return 'CLOSED';
    }
  }
}

enum SymptomSeverity { mild, moderate, severe }

extension SymptomSeverityApi on SymptomSeverity {
  String get apiValue => name.toUpperCase();

  static SymptomSeverity? fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'MILD':
        return SymptomSeverity.mild;
      case 'MODERATE':
        return SymptomSeverity.moderate;
      case 'SEVERE':
        return SymptomSeverity.severe;
      default:
        return null;
    }
  }
}

enum ConfidenceTier { strong, moderate, limited, insufficient }

extension ConfidenceTierApi on ConfidenceTier {
  static ConfidenceTier fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'STRONG':
        return ConfidenceTier.strong;
      case 'MODERATE':
        return ConfidenceTier.moderate;
      case 'LIMITED':
        return ConfidenceTier.limited;
      default:
        return ConfidenceTier.insufficient;
    }
  }

  String labelBn() {
    switch (this) {
      case ConfidenceTier.strong:
        return 'শক্তিশালী';
      case ConfidenceTier.moderate:
        return 'মাঝারি';
      case ConfidenceTier.limited:
        return 'সীমিত';
      case ConfidenceTier.insufficient:
        return 'অপর্যাপ্ত';
    }
  }

  String labelEn() {
    switch (this) {
      case ConfidenceTier.strong:
        return 'Strong';
      case ConfidenceTier.moderate:
        return 'Moderate';
      case ConfidenceTier.limited:
        return 'Limited';
      case ConfidenceTier.insufficient:
        return 'Insufficient';
    }
  }
}

enum UrgencyTier { low, medium, high, critical }

extension UrgencyTierApi on UrgencyTier {
  static UrgencyTier fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'LOW':
        return UrgencyTier.low;
      case 'MEDIUM':
        return UrgencyTier.medium;
      case 'HIGH':
        return UrgencyTier.high;
      case 'CRITICAL':
        return UrgencyTier.critical;
      default:
        return UrgencyTier.low;
    }
  }
}

class SymptomSnapshotModel {
  const SymptomSnapshotModel({
    this.symptomCodes = const [],
    this.freeTextSymptoms = const [],
    this.durationDays,
    this.severity,
    this.normalizedTerms = const [],
  });

  factory SymptomSnapshotModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SymptomSnapshotModel();
    return SymptomSnapshotModel(
      symptomCodes: (json['symptomCodes'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
      freeTextSymptoms: (json['freeTextSymptoms'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
      durationDays: json['durationDays'] as int?,
      severity: SymptomSeverityApi.fromApi(json['severity'] as String?),
      normalizedTerms: (json['normalizedTerms'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
    );
  }

  final List<String> symptomCodes;
  final List<String> freeTextSymptoms;
  final int? durationDays;
  final SymptomSeverity? severity;
  final List<String> normalizedTerms;
}

class SymptomCompletenessModel {
  const SymptomCompletenessModel({
    this.score = 0,
    this.requiredFieldsMet = false,
    this.missingFields = const [],
    this.redFlagScreened = false,
  });

  factory SymptomCompletenessModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SymptomCompletenessModel();
    return SymptomCompletenessModel(
      score: (json['score'] as num?)?.toDouble() ?? 0,
      requiredFieldsMet: json['requiredFieldsMet'] as bool? ?? false,
      missingFields: (json['missingFields'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
      redFlagScreened: json['redFlagScreened'] as bool? ?? false,
    );
  }

  final double score;
  final bool requiredFieldsMet;
  final List<String> missingFields;
  final bool redFlagScreened;
}

class RedFlagItemModel {
  const RedFlagItemModel({
    required this.code,
    required this.labelBn,
    required this.labelEn,
    this.source = 'graph',
  });

  factory RedFlagItemModel.fromJson(Map<String, dynamic> json) {
    return RedFlagItemModel(
      code: json['code'] as String? ?? '',
      labelBn: json['labelBn'] as String? ?? '',
      labelEn: json['labelEn'] as String? ?? '',
      source: json['source'] as String? ?? 'graph',
    );
  }

  final String code;
  final String labelBn;
  final String labelEn;
  final String source;
}

class CaseRiskAssessmentModel {
  const CaseRiskAssessmentModel({
    this.urgencyTier = UrgencyTier.low,
    this.triageBucket = 'LOW',
    this.urgencyLevel = 0,
    this.redFlags = const [],
    this.recommendationBn = '',
    this.recommendationEn = '',
    this.escalationRequired = false,
    this.emergency = false,
  });

  factory CaseRiskAssessmentModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CaseRiskAssessmentModel();
    return CaseRiskAssessmentModel(
      urgencyTier: UrgencyTierApi.fromApi(json['urgencyTier'] as String?),
      triageBucket: json['triageBucket'] as String? ?? 'LOW',
      urgencyLevel: json['urgencyLevel'] as int? ?? 0,
      redFlags: (json['redFlags'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(RedFlagItemModel.fromJson)
          .toList(),
      recommendationBn: json['recommendationBn'] as String? ?? '',
      recommendationEn: json['recommendationEn'] as String? ?? '',
      escalationRequired: json['escalationRequired'] as bool? ?? false,
      emergency: json['emergency'] as bool? ?? false,
    );
  }

  final UrgencyTier urgencyTier;
  final String triageBucket;
  final int urgencyLevel;
  final List<RedFlagItemModel> redFlags;
  final String recommendationBn;
  final String recommendationEn;
  final bool escalationRequired;
  final bool emergency;
}

class GroundedDifferentialModel {
  const GroundedDifferentialModel({
    required this.slug,
    required this.titleBn,
    required this.titleEn,
    required this.rank,
    required this.confidenceScore,
    required this.evidenceLevel,
    this.supportingSymptoms = const [],
    this.citations = const [],
    this.source = 'fused',
  });

  factory GroundedDifferentialModel.fromJson(Map<String, dynamic> json) {
    return GroundedDifferentialModel(
      slug: json['slug'] as String? ?? '',
      titleBn: json['titleBn'] as String? ?? '',
      titleEn: json['titleEn'] as String? ?? '',
      rank: json['rank'] as int? ?? 0,
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0,
      evidenceLevel: json['evidenceLevel'] as String? ?? '',
      supportingSymptoms: (json['supportingSymptoms'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
      citations: (json['citations'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
      source: json['source'] as String? ?? 'fused',
    );
  }

  final String slug;
  final String titleBn;
  final String titleEn;
  final int rank;
  final double confidenceScore;
  final String evidenceLevel;
  final List<String> supportingSymptoms;
  final List<String> citations;
  final String source;
}

class CaseConfidenceModel {
  const CaseConfidenceModel({
    this.retrievalAvg = 0,
    this.differentialTop = 0,
    this.caseScore = 0,
    this.tier = ConfidenceTier.insufficient,
    this.failClosed = false,
  });

  factory CaseConfidenceModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CaseConfidenceModel();
    return CaseConfidenceModel(
      retrievalAvg: (json['retrievalAvg'] as num?)?.toDouble() ?? 0,
      differentialTop: (json['differentialTop'] as num?)?.toDouble() ?? 0,
      caseScore: (json['caseScore'] as num?)?.toDouble() ?? 0,
      tier: ConfidenceTierApi.fromApi(json['tier'] as String?),
      failClosed: json['failClosed'] as bool? ?? false,
    );
  }

  final double retrievalAvg;
  final double differentialTop;
  final double caseScore;
  final ConfidenceTier tier;
  final bool failClosed;
}

class ClarificationQuestionModel {
  const ClarificationQuestionModel({
    required this.field,
    required this.questionBn,
    required this.questionEn,
  });

  factory ClarificationQuestionModel.fromJson(Map<String, dynamic> json) {
    return ClarificationQuestionModel(
      field: json['field'] as String? ?? '',
      questionBn: json['questionBn'] as String? ?? '',
      questionEn: json['questionEn'] as String? ?? '',
    );
  }

  final String field;
  final String questionBn;
  final String questionEn;
}

class SourceCitationModel {
  const SourceCitationModel({
    required this.sourceId,
    required this.title,
    required this.url,
    this.publisher,
  });

  factory SourceCitationModel.fromJson(Map<String, dynamic> json) {
    return SourceCitationModel(
      sourceId: json['sourceId'] as String? ?? json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
      publisher: json['publisher'] as String?,
    );
  }

  final String sourceId;
  final String title;
  final String url;
  final String? publisher;
}

class RetrievedChunkModel {
  const RetrievedChunkModel({
    required this.slug,
    required this.title,
    required this.excerpt,
    required this.inlineCitation,
    this.excerptEn,
    this.headingPath,
    this.evidenceLevel = '',
    this.confidenceScore = 0,
    this.rank = 0,
    this.sources = const [],
  });

  factory RetrievedChunkModel.fromJson(Map<String, dynamic> json) {
    return RetrievedChunkModel(
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
      excerpt: json['excerpt'] as String? ?? '',
      excerptEn: json['excerptEn'] as String?,
      headingPath: json['headingPath'] as String?,
      evidenceLevel: json['evidenceLevel'] as String? ?? '',
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0,
      rank: json['rank'] as int? ?? 0,
      inlineCitation: json['inlineCitation'] as String? ?? '',
      sources: (json['sources'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(SourceCitationModel.fromJson)
          .toList(),
    );
  }

  final String slug;
  final String title;
  final String excerpt;
  final String? excerptEn;
  final String? headingPath;
  final String evidenceLevel;
  final double confidenceScore;
  final int rank;
  final String inlineCitation;
  final List<SourceCitationModel> sources;
}

class KnowledgeContextPackModel {
  const KnowledgeContextPackModel({
    required this.packId,
    this.chunks = const [],
    this.citationBlock = '',
  });

  factory KnowledgeContextPackModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const KnowledgeContextPackModel(packId: '');
    return KnowledgeContextPackModel(
      packId: json['packId'] as String? ?? '',
      chunks: (json['chunks'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(RetrievedChunkModel.fromJson)
          .toList(),
      citationBlock: json['citationBlock'] as String? ?? '',
    );
  }

  final String packId;
  final List<RetrievedChunkModel> chunks;
  final String citationBlock;
}

class AiDoctorCaseModel {
  const AiDoctorCaseModel({
    required this.id,
    required this.species,
    required this.locale,
    required this.state,
    required this.symptomSnapshot,
    required this.completeness,
    this.livestockId,
    this.sessionId,
    this.symptomCheckSessionId,
    this.riskAssessment,
    this.differentials = const [],
    this.confidence,
    this.lastPackId,
    this.escalationIds = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory AiDoctorCaseModel.fromJson(Map<String, dynamic> json) {
    return AiDoctorCaseModel(
      id: json['id'] as String? ?? '',
      species: json['species'] as String? ?? 'OTHER',
      locale: AiLocaleApi.fromApi(json['locale'] as String?),
      state: AiDoctorCaseStateApi.fromApi(json['state'] as String?),
      livestockId: json['livestockId'] as String?,
      sessionId: json['sessionId'] as String?,
      symptomCheckSessionId: json['symptomCheckSessionId'] as String?,
      symptomSnapshot: SymptomSnapshotModel.fromJson(
        json['symptomSnapshot'] as Map<String, dynamic>?,
      ),
      completeness: SymptomCompletenessModel.fromJson(
        json['completeness'] as Map<String, dynamic>?,
      ),
      riskAssessment: json['riskAssessment'] != null
          ? CaseRiskAssessmentModel.fromJson(
              json['riskAssessment'] as Map<String, dynamic>,
            )
          : null,
      differentials: (json['differentials'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(GroundedDifferentialModel.fromJson)
          .toList(),
      confidence: json['confidence'] != null
          ? CaseConfidenceModel.fromJson(
              json['confidence'] as Map<String, dynamic>,
            )
          : null,
      lastPackId: json['lastPackId'] as String?,
      escalationIds: (json['escalationIds'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toSummaryJson() => {
    'id': id,
    'species': species,
    'state': state.apiValue,
    'livestockId': livestockId,
    'updatedAt': updatedAt,
    'createdAt': createdAt,
  };

  factory AiDoctorCaseModel.fromSummaryJson(Map<String, dynamic> json) {
    return AiDoctorCaseModel(
      id: json['id'] as String? ?? '',
      species: json['species'] as String? ?? 'OTHER',
      locale: AiLocale.bn,
      state: AiDoctorCaseStateApi.fromApi(json['state'] as String?),
      livestockId: json['livestockId'] as String?,
      symptomSnapshot: const SymptomSnapshotModel(),
      completeness: const SymptomCompletenessModel(),
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  final String id;
  final String species;
  final AiLocale locale;
  final AiDoctorCaseStateEnum state;
  final String? livestockId;
  final String? sessionId;
  final String? symptomCheckSessionId;
  final SymptomSnapshotModel symptomSnapshot;
  final SymptomCompletenessModel completeness;
  final CaseRiskAssessmentModel? riskAssessment;
  final List<GroundedDifferentialModel> differentials;
  final CaseConfidenceModel? confidence;
  final String? lastPackId;
  final List<String> escalationIds;
  final String? createdAt;
  final String? updatedAt;

  bool get isEmergency =>
      state == AiDoctorCaseStateEnum.emergencyTriage ||
      (riskAssessment?.emergency ?? false);

  bool get canChat =>
      state == AiDoctorCaseStateEnum.responseDelivered ||
      state == AiDoctorCaseStateEnum.awaitingClarification ||
      state == AiDoctorCaseStateEnum.analyzing;
}

class AnalyzeCaseResultModel {
  const AnalyzeCaseResultModel({
    required this.aiCase,
    required this.refused,
    required this.content,
    required this.differentials,
    required this.confidence,
    required this.riskAssessment,
    required this.humanRedirect,
    required this.escalationRecommended,
    required this.disclaimer,
    this.clarificationQuestions = const [],
    this.emergencyHandoff = false,
    this.pack,
  });

  factory AnalyzeCaseResultModel.fromJson(Map<String, dynamic> json) {
    final caseJson = json['case'] as Map<String, dynamic>? ?? {};
    return AnalyzeCaseResultModel(
      aiCase: AiDoctorCaseModel.fromJson(caseJson),
      refused: json['refused'] as bool? ?? false,
      content: json['content'] as String? ?? '',
      differentials: (json['differentials'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(GroundedDifferentialModel.fromJson)
          .toList(),
      confidence: CaseConfidenceModel.fromJson(
        json['confidence'] as Map<String, dynamic>?,
      ),
      riskAssessment: CaseRiskAssessmentModel.fromJson(
        json['riskAssessment'] as Map<String, dynamic>?,
      ),
      clarificationQuestions:
          (json['clarificationQuestions'] as List<dynamic>? ?? [])
              .whereType<Map<String, dynamic>>()
              .map(ClarificationQuestionModel.fromJson)
              .toList(),
      emergencyHandoff: json['emergencyHandoff'] as bool? ?? false,
      humanRedirect: json['humanRedirect'] as bool? ?? false,
      escalationRecommended: json['escalationRecommended'] as bool? ?? false,
      pack: json['pack'] != null
          ? KnowledgeContextPackModel.fromJson(
              json['pack'] as Map<String, dynamic>,
            )
          : null,
      disclaimer: json['disclaimer'] as String? ?? '',
    );
  }

  final AiDoctorCaseModel aiCase;
  final bool refused;
  final String content;
  final List<GroundedDifferentialModel> differentials;
  final CaseConfidenceModel confidence;
  final CaseRiskAssessmentModel riskAssessment;
  final List<ClarificationQuestionModel> clarificationQuestions;
  final bool emergencyHandoff;
  final bool humanRedirect;
  final bool escalationRecommended;
  final KnowledgeContextPackModel? pack;
  final String disclaimer;
}

class CreateAiDoctorCaseInput {
  const CreateAiDoctorCaseInput({
    required this.species,
    this.livestockId,
    this.locale = AiLocale.bn,
    this.symptomCheckSessionId,
  });

  Map<String, dynamic> toJson() => {
    'species': species,
    if (livestockId != null) 'livestockId': livestockId,
    'locale': locale.apiValue,
    if (symptomCheckSessionId != null)
      'symptomCheckSessionId': symptomCheckSessionId,
  };

  final String species;
  final String? livestockId;
  final AiLocale locale;
  final String? symptomCheckSessionId;
}

class SubmitIntakeInput {
  const SubmitIntakeInput({
    required this.symptomCodes,
    this.freeTextSymptoms,
    this.durationDays,
    this.severity,
  });

  Map<String, dynamic> toJson() => {
    'symptomCodes': symptomCodes,
    if (freeTextSymptoms != null && freeTextSymptoms!.isNotEmpty)
      'freeTextSymptoms': freeTextSymptoms,
    if (durationDays != null) 'durationDays': durationDays,
    if (severity != null) 'severity': severity!.apiValue,
  };

  final List<String> symptomCodes;
  final List<String>? freeTextSymptoms;
  final int? durationDays;
  final SymptomSeverity? severity;
}

class AiDoctorAssistantInput {
  const AiDoctorAssistantInput({
    required this.message,
    required this.caseId,
    this.sessionId,
    this.livestockId,
    this.locale = AiLocale.bn,
  });

  Map<String, dynamic> toJson() => {
    'message': message.trim(),
    'caseId': caseId,
    if (sessionId != null) 'sessionId': sessionId,
    if (livestockId != null) 'livestockId': livestockId,
    'locale': locale.apiValue,
  };

  final String message;
  final String caseId;
  final String? sessionId;
  final String? livestockId;
  final AiLocale locale;
}

class AiDoctorAssistantResponse {
  const AiDoctorAssistantResponse({
    required this.sessionId,
    required this.messageId,
    required this.content,
    required this.refused,
    required this.humanRedirect,
    required this.escalationRecommended,
    required this.disclaimer,
    this.pack,
  });

  factory AiDoctorAssistantResponse.fromJson(Map<String, dynamic> json) {
    return AiDoctorAssistantResponse(
      sessionId: json['sessionId'] as String? ?? '',
      messageId: json['messageId'] as String? ?? '',
      content: json['content'] as String? ?? '',
      refused: json['refused'] as bool? ?? false,
      humanRedirect: json['humanRedirect'] as bool? ?? false,
      escalationRecommended: json['escalationRecommended'] as bool? ?? false,
      disclaimer: json['disclaimer'] as String? ?? '',
      pack: json['pack'] != null
          ? KnowledgeContextPackModel.fromJson(
              json['pack'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  final String sessionId;
  final String messageId;
  final String content;
  final bool refused;
  final bool humanRedirect;
  final bool escalationRecommended;
  final String disclaimer;
  final KnowledgeContextPackModel? pack;
}

class EscalateCaseResultModel {
  const EscalateCaseResultModel({
    required this.aiCase,
    required this.escalationId,
  });

  factory EscalateCaseResultModel.fromJson(Map<String, dynamic> json) {
    return EscalateCaseResultModel(
      aiCase: AiDoctorCaseModel.fromJson(
        json['case'] as Map<String, dynamic>? ?? {},
      ),
      escalationId: json['escalationId'] as String? ?? '',
    );
  }

  final AiDoctorCaseModel aiCase;
  final String escalationId;
}

enum AiDoctorMessageRole { user, assistant, system }

class AiDoctorChatMessage {
  const AiDoctorChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.refused = false,
    this.humanRedirect = false,
    this.escalationRecommended = false,
    this.disclaimer,
    this.analysis,
    this.isSending = false,
  });

  final String id;
  final AiDoctorMessageRole role;
  final String content;
  final DateTime createdAt;
  final bool refused;
  final bool humanRedirect;
  final bool escalationRecommended;
  final String? disclaimer;
  final AnalyzeCaseResultModel? analysis;
  final bool isSending;

  AiDoctorChatMessage copyWith({
    String? id,
    AiDoctorMessageRole? role,
    String? content,
    DateTime? createdAt,
    bool? refused,
    bool? humanRedirect,
    bool? escalationRecommended,
    String? disclaimer,
    AnalyzeCaseResultModel? analysis,
    bool? isSending,
  }) {
    return AiDoctorChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      refused: refused ?? this.refused,
      humanRedirect: humanRedirect ?? this.humanRedirect,
      escalationRecommended:
          escalationRecommended ?? this.escalationRecommended,
      disclaimer: disclaimer ?? this.disclaimer,
      analysis: analysis ?? this.analysis,
      isSending: isSending ?? this.isSending,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role.name,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'refused': refused,
    'humanRedirect': humanRedirect,
    'escalationRecommended': escalationRecommended,
    'disclaimer': disclaimer,
  };

  factory AiDoctorChatMessage.fromJson(Map<String, dynamic> json) {
    return AiDoctorChatMessage(
      id: json['id'] as String? ?? '',
      role: AiDoctorMessageRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => AiDoctorMessageRole.system,
      ),
      content: json['content'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      refused: json['refused'] as bool? ?? false,
      humanRedirect: json['humanRedirect'] as bool? ?? false,
      escalationRecommended: json['escalationRecommended'] as bool? ?? false,
      disclaimer: json['disclaimer'] as String?,
    );
  }

  static AiDoctorChatMessage fromAnalysis(AnalyzeCaseResultModel result) {
    return AiDoctorChatMessage(
      id: 'analysis-${result.aiCase.id}-${DateTime.now().millisecondsSinceEpoch}',
      role: AiDoctorMessageRole.assistant,
      content: result.content,
      createdAt: DateTime.now(),
      refused: result.refused,
      humanRedirect: result.humanRedirect,
      escalationRecommended: result.escalationRecommended,
      disclaimer: result.disclaimer,
      analysis: result,
    );
  }

  static AiDoctorChatMessage fromAssistant(AiDoctorAssistantResponse response) {
    return AiDoctorChatMessage(
      id: response.messageId,
      role: AiDoctorMessageRole.assistant,
      content: response.content,
      createdAt: DateTime.now(),
      refused: response.refused,
      humanRedirect: response.humanRedirect,
      escalationRecommended: response.escalationRecommended,
      disclaimer: response.disclaimer,
    );
  }
}

enum EscalationChannel {
  vetCallNow,
  vetBooking,
  asyncVetReview,
  clinicFinder,
}

extension EscalationChannelLabels on EscalationChannel {
  String labelBn() {
    switch (this) {
      case EscalationChannel.vetCallNow:
        return 'এখনই ভেটের সাথে কথা বলুন';
      case EscalationChannel.vetBooking:
        return 'পরামর্শ বুক করুন';
      case EscalationChannel.asyncVetReview:
        return 'অ্যাসিঙ্ক ভেট রিভিউ';
      case EscalationChannel.clinicFinder:
        return 'কাছের ক্লিনিক খুঁজুন';
    }
  }
}
