class FeedRecommendation {
  const FeedRecommendation({
    required this.ruleVersion,
    required this.planDate,
    required this.items,
    required this.totals,
    required this.warnings,
    required this.disclaimerBn,
    this.livestockId,
    this.intelligence,
    this.fromCache = false,
  });

  final String ruleVersion;
  final String planDate;
  final List<RecommendationItem> items;
  final RecommendationTotals totals;
  final List<String> warnings;
  final String disclaimerBn;
  final String? livestockId;
  final RecommendationIntelligence? intelligence;
  final bool fromCache;

  factory FeedRecommendation.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
  }) {
    final itemsRaw = json['items'] as List<dynamic>? ?? const [];
    final warningsRaw = json['warnings'] as List<dynamic>? ?? const [];
    final totalsRaw = json['totals'] as Map<String, dynamic>? ?? const {};
    RecommendationIntelligence? intelligence;
    if (totalsRaw['intelligence'] is Map<String, dynamic>) {
      intelligence = RecommendationIntelligence.fromJson(
        totalsRaw['intelligence'] as Map<String, dynamic>,
      );
    } else if (json['scores'] is Map<String, dynamic>) {
      intelligence = RecommendationIntelligence(
        scores: RecommendationScoreBreakdown.fromJson(
          json['scores'] as Map<String, dynamic>,
        ),
        explanations: (json['explanations'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(RecommendationExplanation.fromJson)
            .toList(),
        alternatives: (json['alternatives'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(RecommendationAlternative.fromJson)
            .toList(),
      );
    }
    final totals = RecommendationTotals.fromJson(totalsRaw);
    intelligence ??= totals.intelligence;
    return FeedRecommendation(
      ruleVersion: json['ruleVersion'] as String? ?? '',
      planDate: json['planDate'] as String? ?? '',
      items: itemsRaw
          .whereType<Map<String, dynamic>>()
          .map(RecommendationItem.fromJson)
          .toList(),
      totals: totals,
      warnings: warningsRaw.map((w) => w.toString()).toList(),
      disclaimerBn: json['disclaimerBn'] as String? ?? '',
      livestockId: json['livestockId'] as String?,
      intelligence: intelligence,
      fromCache: fromCache,
    );
  }
}

class RecommendationItem {
  const RecommendationItem({
    required this.feedItemId,
    required this.nameBn,
    required this.amountKg,
    required this.costBdt,
  });

  final String feedItemId;
  final String nameBn;
  final double amountKg;
  final double costBdt;

  factory RecommendationItem.fromJson(Map<String, dynamic> json) =>
      RecommendationItem(
        feedItemId: json['feedItemId'] as String,
        nameBn: json['nameBn'] as String? ?? '',
        amountKg: (json['amountKg'] as num?)?.toDouble() ?? 0,
        costBdt: (json['costBdt'] as num?)?.toDouble() ?? 0,
      );
}

class RecommendationTotals {
  const RecommendationTotals({
    required this.dryMatterKg,
    required this.estimatedCostBdt,
    required this.itemCount,
    this.intelligence,
  });

  final double dryMatterKg;
  final double estimatedCostBdt;
  final int itemCount;
  final RecommendationIntelligence? intelligence;

  factory RecommendationTotals.fromJson(Map<String, dynamic> json) =>
      RecommendationTotals(
        dryMatterKg: (json['dryMatterKg'] as num?)?.toDouble() ?? 0,
        estimatedCostBdt: (json['estimatedCostBdt'] as num?)?.toDouble() ?? 0,
        itemCount: json['itemCount'] as int? ?? 0,
        intelligence: json['intelligence'] is Map<String, dynamic>
            ? RecommendationIntelligence.fromJson(
                json['intelligence'] as Map<String, dynamic>,
              )
            : null,
      );
}

class RecommendationScoreBreakdown {
  const RecommendationScoreBreakdown({
    required this.nutritionFit,
    required this.affordability,
    required this.seasonalFit,
    required this.healthSafety,
    required this.overall,
  });

  final double nutritionFit;
  final double affordability;
  final double seasonalFit;
  final double healthSafety;
  final double overall;

  factory RecommendationScoreBreakdown.fromJson(Map<String, dynamic> json) =>
      RecommendationScoreBreakdown(
        nutritionFit: (json['nutritionFit'] as num?)?.toDouble() ?? 0,
        affordability: (json['affordability'] as num?)?.toDouble() ?? 0,
        seasonalFit: (json['seasonalFit'] as num?)?.toDouble() ?? 0,
        healthSafety: (json['healthSafety'] as num?)?.toDouble() ?? 0,
        overall: (json['overall'] as num?)?.toDouble() ?? 0,
      );
}

class RecommendationExplanation {
  const RecommendationExplanation({
    required this.ruleId,
    required this.ruleNameBn,
    required this.effect,
    required this.impactBn,
  });

  final String ruleId;
  final String ruleNameBn;
  final String effect;
  final String impactBn;

  factory RecommendationExplanation.fromJson(Map<String, dynamic> json) =>
      RecommendationExplanation(
        ruleId: json['ruleId'] as String? ?? '',
        ruleNameBn: json['ruleNameBn'] as String? ?? '',
        effect: json['effect'] as String? ?? '',
        impactBn: json['impactBn'] as String? ?? '',
      );
}

class RecommendationAlternative {
  const RecommendationAlternative({
    required this.originalFeedItemId,
    required this.alternativeFeedItemId,
    required this.nameBn,
    required this.savingsBdt,
    required this.tradeoffBn,
  });

  final String originalFeedItemId;
  final String alternativeFeedItemId;
  final String nameBn;
  final double savingsBdt;
  final String tradeoffBn;

  factory RecommendationAlternative.fromJson(Map<String, dynamic> json) =>
      RecommendationAlternative(
        originalFeedItemId: json['originalFeedItemId'] as String? ?? '',
        alternativeFeedItemId: json['alternativeFeedItemId'] as String? ?? '',
        nameBn: json['nameBn'] as String? ?? '',
        savingsBdt: (json['savingsBdt'] as num?)?.toDouble() ?? 0,
        tradeoffBn: json['tradeoffBn'] as String? ?? '',
      );
}

class RecommendationIntelligence {
  const RecommendationIntelligence({
    required this.scores,
    this.explanations = const [],
    this.alternatives = const [],
  });

  final RecommendationScoreBreakdown scores;
  final List<RecommendationExplanation> explanations;
  final List<RecommendationAlternative> alternatives;

  factory RecommendationIntelligence.fromJson(Map<String, dynamic> json) {
    final scoresRaw = json['scores'] as Map<String, dynamic>? ?? json;
    return RecommendationIntelligence(
      scores: RecommendationScoreBreakdown.fromJson(scoresRaw),
      explanations: (json['explanations'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(RecommendationExplanation.fromJson)
          .toList(),
      alternatives: (json['alternatives'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(RecommendationAlternative.fromJson)
          .toList(),
    );
  }
}
