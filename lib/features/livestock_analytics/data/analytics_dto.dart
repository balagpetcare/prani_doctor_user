class AnalyticsPeriod {
  const AnalyticsPeriod({required this.from, required this.to});

  final String from;
  final String to;

  factory AnalyticsPeriod.fromJson(Map<String, dynamic> json) => AnalyticsPeriod(
    from: json['from'] as String? ?? '',
    to: json['to'] as String? ?? '',
  );
}

class LivestockDashboardMetrics {
  const LivestockDashboardMetrics({
    required this.farmRef,
    required this.period,
    required this.totalAnimals,
    required this.activeAnimals,
    required this.feedCostBdt,
    required this.livestockExpenseBdt,
    required this.totalExpenseBdt,
    required this.lowStockCount,
    this.bySpecies = const {},
    this.fromCache = false,
  });

  final String farmRef;
  final AnalyticsPeriod period;
  final int totalAnimals;
  final int activeAnimals;
  final double feedCostBdt;
  final double livestockExpenseBdt;
  final double totalExpenseBdt;
  final int lowStockCount;
  final Map<String, int> bySpecies;
  final bool fromCache;

  factory LivestockDashboardMetrics.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
  }) {
    final animalCount = json['animalCount'] as Map<String, dynamic>? ?? {};
    final bySpeciesRaw = animalCount['bySpecies'] as Map<String, dynamic>? ?? {};
    return LivestockDashboardMetrics(
      farmRef: json['farmRef'] as String? ?? '',
      period: AnalyticsPeriod.fromJson(
        json['period'] as Map<String, dynamic>? ?? const {},
      ),
      totalAnimals: animalCount['total'] as int? ?? 0,
      activeAnimals: animalCount['active'] as int? ?? 0,
      feedCostBdt: (json['feedCostBdt'] as num?)?.toDouble() ?? 0,
      livestockExpenseBdt: (json['livestockExpenseBdt'] as num?)?.toDouble() ?? 0,
      totalExpenseBdt: (json['totalExpenseBdt'] as num?)?.toDouble() ?? 0,
      lowStockCount: json['lowStockCount'] as int? ?? 0,
      bySpecies: bySpeciesRaw.map(
        (key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0),
      ),
      fromCache: fromCache,
    );
  }
}

class FeedEfficiencyMetrics {
  const FeedEfficiencyMetrics({
    required this.farmRef,
    required this.period,
    required this.totalFeedKg,
    required this.totalFeedCostBdt,
    required this.activeLivestockCount,
    this.costPerLivestockBdt,
    this.avgFeedKgPerLivestock,
    this.fromCache = false,
  });

  final String farmRef;
  final AnalyticsPeriod period;
  final double totalFeedKg;
  final double totalFeedCostBdt;
  final int activeLivestockCount;
  final double? costPerLivestockBdt;
  final double? avgFeedKgPerLivestock;
  final bool fromCache;

  factory FeedEfficiencyMetrics.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
  }) =>
      FeedEfficiencyMetrics(
        farmRef: json['farmRef'] as String? ?? '',
        period: AnalyticsPeriod.fromJson(
          json['period'] as Map<String, dynamic>? ?? const {},
        ),
        totalFeedKg: (json['totalFeedKg'] as num?)?.toDouble() ?? 0,
        totalFeedCostBdt: (json['totalFeedCostBdt'] as num?)?.toDouble() ?? 0,
        activeLivestockCount: json['activeLivestockCount'] as int? ?? 0,
        costPerLivestockBdt: (json['costPerLivestockBdt'] as num?)?.toDouble(),
        avgFeedKgPerLivestock:
            (json['avgFeedKgPerLivestock'] as num?)?.toDouble(),
        fromCache: fromCache,
      );
}

class ExpenseBreakdownItem {
  const ExpenseBreakdownItem({
    required this.category,
    required this.amountBdt,
  });

  final String category;
  final double amountBdt;

  factory ExpenseBreakdownItem.fromJson(Map<String, dynamic> json) =>
      ExpenseBreakdownItem(
        category: json['category'] as String? ?? '',
        amountBdt: (json['amountBdt'] as num?)?.toDouble() ?? 0,
      );
}

class ProfitLossMetrics {
  const ProfitLossMetrics({
    required this.farmRef,
    required this.period,
    required this.livestockExpenseBdt,
    required this.feedConsumptionCostBdt,
    required this.totalExpenseBdt,
    required this.breakdown,
    this.fromCache = false,
  });

  final String farmRef;
  final AnalyticsPeriod period;
  final double livestockExpenseBdt;
  final double feedConsumptionCostBdt;
  final double totalExpenseBdt;
  final List<ExpenseBreakdownItem> breakdown;
  final bool fromCache;

  factory ProfitLossMetrics.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
  }) {
    final breakdownRaw = json['breakdownByCategory'] as List<dynamic>? ?? [];
    return ProfitLossMetrics(
      farmRef: json['farmRef'] as String? ?? '',
      period: AnalyticsPeriod.fromJson(
        json['period'] as Map<String, dynamic>? ?? const {},
      ),
      livestockExpenseBdt: (json['livestockExpenseBdt'] as num?)?.toDouble() ?? 0,
      feedConsumptionCostBdt:
          (json['feedConsumptionCostBdt'] as num?)?.toDouble() ?? 0,
      totalExpenseBdt: (json['totalExpenseBdt'] as num?)?.toDouble() ?? 0,
      breakdown: breakdownRaw
          .whereType<Map<String, dynamic>>()
          .map(ExpenseBreakdownItem.fromJson)
          .toList(),
      fromCache: fromCache,
    );
  }
}
