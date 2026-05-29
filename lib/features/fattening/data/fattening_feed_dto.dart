import '../../feed/data/feed_dto.dart';

enum BatchFeedPlanMode { normal, fattening }

extension BatchFeedPlanModeApi on BatchFeedPlanMode {
  String get apiValue => name.toUpperCase();

  static BatchFeedPlanMode fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'NORMAL':
        return BatchFeedPlanMode.normal;
      default:
        return BatchFeedPlanMode.fattening;
    }
  }
}

class BatchFeedPlan {
  const BatchFeedPlan({
    required this.id,
    required this.batchId,
    required this.mode,
    this.dailyAmountKg,
    this.dailyCostBdt,
    this.feedType,
    this.unit,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String batchId;
  final BatchFeedPlanMode mode;
  final double? dailyAmountKg;
  final double? dailyCostBdt;
  final FeedType? feedType;
  final FeedUnit? unit;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory BatchFeedPlan.fromJson(Map<String, dynamic> json) {
    return BatchFeedPlan(
      id: json['id'] as String,
      batchId: json['batchId'] as String,
      mode: BatchFeedPlanModeApi.fromApi(json['mode'] as String?),
      dailyAmountKg: json['dailyAmountKg'] == null
          ? null
          : double.tryParse(json['dailyAmountKg'].toString()),
      dailyCostBdt: json['dailyCostBdt'] == null
          ? null
          : double.tryParse(json['dailyCostBdt'].toString()),
      feedType: json['feedType'] == null
          ? null
          : FeedTypeApi.fromApi(json['feedType'] as String),
      unit: json['unit'] == null
          ? null
          : FeedUnitApi.fromApi(json['unit'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toUpsertJson() => {
    'mode': mode.apiValue,
    if (dailyAmountKg != null) 'dailyAmountKg': dailyAmountKg,
    if (dailyCostBdt != null) 'dailyCostBdt': dailyCostBdt,
    if (feedType != null) 'feedType': feedType!.apiValue,
    if (unit != null) 'unit': unit!.apiValue,
    if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
  };
}

class BatchFeedDashboard {
  const BatchFeedDashboard({
    required this.batchId,
    this.plan,
    required this.feedCost,
    required this.dailyFeed,
    required this.daily,
    this.fromCache = false,
  });

  final String batchId;
  final BatchFeedPlan? plan;
  final BatchFeedCostSummary feedCost;
  final BatchDailyFeedSummary dailyFeed;
  final List<BatchFeedDailyPoint> daily;
  final bool fromCache;

  factory BatchFeedDashboard.fromJson(Map<String, dynamic> json) {
    final cost = json['feedCost'] as Map<String, dynamic>? ?? {};
    final dailyFeedJson = json['dailyFeed'] as Map<String, dynamic>? ?? {};
    return BatchFeedDashboard(
      batchId: json['batchId'] as String,
      plan: json['plan'] is Map<String, dynamic>
          ? BatchFeedPlan.fromJson(json['plan'] as Map<String, dynamic>)
          : null,
      feedCost: BatchFeedCostSummary.fromJson(cost),
      dailyFeed: BatchDailyFeedSummary.fromJson(dailyFeedJson),
      daily: (json['daily'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(BatchFeedDailyPoint.fromJson)
          .toList(),
      fromCache: json['fromCache'] as bool? ?? false,
    );
  }
}

class BatchFeedCostSummary {
  const BatchFeedCostSummary({
    required this.totalCostBdt,
    required this.totalAmount,
    required this.todayCostBdt,
    required this.todayAmount,
    required this.avgDailyCostBdt,
    required this.avgDailyAmount,
  });

  final double totalCostBdt;
  final double totalAmount;
  final double todayCostBdt;
  final double todayAmount;
  final double avgDailyCostBdt;
  final double avgDailyAmount;

  factory BatchFeedCostSummary.fromJson(Map<String, dynamic> json) {
    double n(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;
    return BatchFeedCostSummary(
      totalCostBdt: n(json['totalCostBdt']),
      totalAmount: n(json['totalAmount']),
      todayCostBdt: n(json['todayCostBdt']),
      todayAmount: n(json['todayAmount']),
      avgDailyCostBdt: n(json['avgDailyCostBdt']),
      avgDailyAmount: n(json['avgDailyAmount']),
    );
  }
}

class BatchDailyFeedSummary {
  const BatchDailyFeedSummary({
    this.plannedAmountKg,
    this.plannedCostBdt,
    required this.todayAmountKg,
    required this.todayCostBdt,
    this.mode,
  });

  final double? plannedAmountKg;
  final double? plannedCostBdt;
  final double todayAmountKg;
  final double todayCostBdt;
  final String? mode;

  factory BatchDailyFeedSummary.fromJson(Map<String, dynamic> json) {
    double? opt(dynamic v) =>
        v == null ? null : double.tryParse(v.toString());
    double n(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;
    return BatchDailyFeedSummary(
      plannedAmountKg: opt(json['plannedAmountKg']),
      plannedCostBdt: opt(json['plannedCostBdt']),
      todayAmountKg: n(json['todayAmountKg']),
      todayCostBdt: n(json['todayCostBdt']),
      mode: json['mode'] as String?,
    );
  }
}

class BatchFeedDailyPoint {
  const BatchFeedDailyPoint({
    required this.date,
    required this.costBdt,
    required this.amount,
  });

  final String date;
  final double costBdt;
  final double amount;

  factory BatchFeedDailyPoint.fromJson(Map<String, dynamic> json) {
    return BatchFeedDailyPoint(
      date: json['date'] as String,
      costBdt: double.tryParse(json['costBdt']?.toString() ?? '') ?? 0,
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
    );
  }
}
