class SymptomTaxonomyModel {
  const SymptomTaxonomyModel({
    required this.species,
    required this.bodySystems,
  });

  factory SymptomTaxonomyModel.fromJson(Map<String, dynamic> json) {
    return SymptomTaxonomyModel(
      species: json['species'] as String? ?? '',
      bodySystems: (json['bodySystems'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(BodySystemSymptoms.fromJson)
          .toList(),
    );
  }

  final String species;
  final List<BodySystemSymptoms> bodySystems;
}

class BodySystemSymptoms {
  const BodySystemSymptoms({
    required this.bodySystem,
    required this.symptoms,
  });

  factory BodySystemSymptoms.fromJson(Map<String, dynamic> json) {
    return BodySystemSymptoms(
      bodySystem: json['bodySystem'] as String? ?? '',
      symptoms: (json['symptoms'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(SymptomNodeModel.fromJson)
          .toList(),
    );
  }

  final String bodySystem;
  final List<SymptomNodeModel> symptoms;
}

class SymptomNodeModel {
  const SymptomNodeModel({
    required this.code,
    required this.labelBn,
    required this.labelEn,
    required this.redFlag,
  });

  factory SymptomNodeModel.fromJson(Map<String, dynamic> json) {
    return SymptomNodeModel(
      code: json['code'] as String? ?? '',
      labelBn: json['labelBn'] as String? ?? '',
      labelEn: json['labelEn'] as String? ?? '',
      redFlag: json['redFlag'] as bool? ?? false,
    );
  }

  final String code;
  final String labelBn;
  final String labelEn;
  final bool redFlag;
}

class SymptomCheckInput {
  const SymptomCheckInput({
    required this.species,
    required this.symptomCodes,
    this.livestockId,
    this.freeTextSymptoms,
    this.severity,
  });

  Map<String, dynamic> toJson() => {
    'species': species,
    'symptomCodes': symptomCodes,
    if (livestockId != null) 'livestockId': livestockId,
    if (freeTextSymptoms != null) 'freeTextSymptoms': freeTextSymptoms,
    if (severity != null) 'severity': severity,
  };

  final String species;
  final List<String> symptomCodes;
  final String? livestockId;
  final List<String>? freeTextSymptoms;
  final String? severity;
}

class SymptomCheckResultModel {
  const SymptomCheckResultModel({
    required this.sessionId,
    required this.confidence,
    required this.triageBucket,
    required this.urgencyLevel,
    required this.recommendation,
    required this.escalationRequired,
    required this.emergency,
    required this.redFlags,
    required this.differentials,
  });

  factory SymptomCheckResultModel.fromJson(Map<String, dynamic> json) {
    return SymptomCheckResultModel(
      sessionId: json['sessionId'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      triageBucket: json['triageBucket'] as String? ?? 'LOW',
      urgencyLevel: json['urgencyLevel'] as int? ?? 0,
      recommendation: json['recommendation'] as String? ?? '',
      escalationRequired: json['escalationRequired'] as bool? ?? false,
      emergency: json['emergency'] as bool? ?? false,
      redFlags: (json['redFlags'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList(),
      differentials: (json['differentials'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList(),
    );
  }

  final String sessionId;
  final double confidence;
  final String triageBucket;
  final int urgencyLevel;
  final String recommendation;
  final bool escalationRequired;
  final bool emergency;
  final List<Map<String, dynamic>> redFlags;
  final List<Map<String, dynamic>> differentials;
}

class KnowledgeHitModel {
  const KnowledgeHitModel({
    required this.id,
    required this.slug,
    required this.title,
    required this.excerpt,
  });

  factory KnowledgeHitModel.fromJson(Map<String, dynamic> json) {
    return KnowledgeHitModel(
      id: json['id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
      excerpt: json['excerpt'] as String? ?? '',
    );
  }

  final String id;
  final String slug;
  final String title;
  final String excerpt;
}

class SmartRecommendationModel {
  const SmartRecommendationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.explanation,
    required this.priority,
    this.deepLink,
  });

  factory SmartRecommendationModel.fromJson(Map<String, dynamic> json) {
    return SmartRecommendationModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      priority: json['priority'] as int? ?? 3,
      deepLink: json['deepLink'] as String?,
    );
  }

  final String id;
  final String type;
  final String title;
  final String explanation;
  final int priority;
  final String? deepLink;
}

class SmartAlertModel {
  const SmartAlertModel({
    required this.id,
    required this.title,
    required this.body,
    required this.priority,
    this.deepLink,
  });

  factory SmartAlertModel.fromJson(Map<String, dynamic> json) {
    return SmartAlertModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      priority: json['priority'] as String? ?? 'MEDIUM',
      deepLink: json['deepLink'] as String?,
    );
  }

  final String id;
  final String title;
  final String body;
  final String priority;
  final String? deepLink;
}

class FarmHealthDashboardModel {
  const FarmHealthDashboardModel({
    required this.farmRef,
    required this.livestockCount,
    required this.herdHealthScore,
    required this.farmRiskScore,
    required this.recommendations,
  });

  factory FarmHealthDashboardModel.fromJson(Map<String, dynamic> json) {
    return FarmHealthDashboardModel(
      farmRef: json['farmRef'] as String? ?? '',
      livestockCount: json['livestockCount'] as int? ?? 0,
      herdHealthScore: json['herdHealthScore'] as int? ?? 0,
      farmRiskScore: json['farmRiskScore'] as int? ?? 0,
      recommendations: (json['recommendations'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(SmartRecommendationModel.fromJson)
          .toList(),
    );
  }

  final String farmRef;
  final int livestockCount;
  final int herdHealthScore;
  final int farmRiskScore;
  final List<SmartRecommendationModel> recommendations;
}

class FollowUpModel {
  const FollowUpModel({
    required this.id,
    required this.title,
    required this.action,
    this.dueDate,
    this.deepLink,
  });

  factory FollowUpModel.fromJson(Map<String, dynamic> json) {
    return FollowUpModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      action: json['action'] as String? ?? '',
      dueDate: json['dueDate'] as String?,
      deepLink: json['deepLink'] as String?,
    );
  }

  final String id;
  final String title;
  final String action;
  final String? dueDate;
  final String? deepLink;
}
