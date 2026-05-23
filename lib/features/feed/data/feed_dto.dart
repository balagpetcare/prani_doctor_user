enum FeedType { grass, straw, concentrate, mineral, silage, other }

enum FeedUnit { kg, bag, bundle, liter, other }

enum FeedTarget { animal, group }

extension FeedTypeApi on FeedType {
  String get apiValue => name.toUpperCase();

  static FeedType fromApi(String value) {
    return FeedType.values.firstWhere(
      (t) => t.apiValue == value.toUpperCase(),
      orElse: () => FeedType.other,
    );
  }
}

extension FeedUnitApi on FeedUnit {
  String get apiValue => name.toUpperCase();

  static FeedUnit fromApi(String value) {
    return FeedUnit.values.firstWhere(
      (u) => u.apiValue == value.toUpperCase(),
      orElse: () => FeedUnit.other,
    );
  }
}

class FeedRecord {
  const FeedRecord({
    required this.id,
    required this.customerId,
    this.farmRef,
    this.animalId,
    this.animalName,
    this.batchId,
    this.batchName,
    required this.feedType,
    required this.amount,
    required this.unit,
    this.costBdt,
    required this.recordedDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.pendingSync = false,
    this.fromCache = false,
  });

  final String id;
  final String customerId;
  final String? farmRef;
  final String? animalId;
  final String? animalName;
  final String? batchId;
  final String? batchName;
  final FeedType feedType;
  final double amount;
  final FeedUnit unit;
  final double? costBdt;
  final DateTime recordedDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool pendingSync;
  final bool fromCache;

  String get targetLabel =>
      animalName ?? batchName ?? animalId ?? batchId ?? '—';

  FeedRecord copyWith({
    String? farmRef,
    String? animalId,
    String? animalName,
    String? batchId,
    String? batchName,
    FeedType? feedType,
    double? amount,
    FeedUnit? unit,
    double? costBdt,
    DateTime? recordedDate,
    String? notes,
    bool? pendingSync,
    bool? fromCache,
    DateTime? updatedAt,
  }) {
    return FeedRecord(
      id: id,
      customerId: customerId,
      farmRef: farmRef ?? this.farmRef,
      animalId: animalId ?? this.animalId,
      animalName: animalName ?? this.animalName,
      batchId: batchId ?? this.batchId,
      batchName: batchName ?? this.batchName,
      feedType: feedType ?? this.feedType,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      costBdt: costBdt ?? this.costBdt,
      recordedDate: recordedDate ?? this.recordedDate,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingSync: pendingSync ?? this.pendingSync,
      fromCache: fromCache ?? this.fromCache,
    );
  }

  factory FeedRecord.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
    bool pendingSync = false,
  }) {
    return FeedRecord(
      id: json['id'] as String,
      customerId: json['customerId'] as String? ?? '',
      farmRef: json['farmRef'] as String?,
      animalId: json['animalId'] as String?,
      animalName: json['animalName'] as String?,
      batchId: json['batchId'] as String?,
      batchName: json['batchName'] as String?,
      feedType: FeedTypeApi.fromApi(json['feedType'] as String? ?? 'OTHER'),
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
      unit: FeedUnitApi.fromApi(json['unit'] as String? ?? 'KG'),
      costBdt: json['costBdt'] == null
          ? null
          : double.tryParse(json['costBdt'].toString()),
      recordedDate:
          DateTime.tryParse(json['recordedDate'] as String? ?? '') ??
          DateTime.now(),
      notes: json['notes'] as String?,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      pendingSync: pendingSync,
      fromCache: fromCache,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerId': customerId,
    if (farmRef != null) 'farmRef': farmRef,
    if (animalId != null) 'animalId': animalId,
    if (animalName != null) 'animalName': animalName,
    if (batchId != null) 'batchId': batchId,
    if (batchName != null) 'batchName': batchName,
    'feedType': feedType.apiValue,
    'amount': amount.toStringAsFixed(3),
    'unit': unit.apiValue,
    if (costBdt != null) 'costBdt': costBdt!.toStringAsFixed(2),
    'recordedDate': _dateOnly(recordedDate),
    if (notes != null) 'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'pendingSync': pendingSync,
  };
}

String _dateOnly(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class FeedInput {
  const FeedInput({
    this.farmRef,
    this.animalId,
    this.batchId,
    this.batchName,
    required this.feedType,
    required this.amount,
    required this.unit,
    this.costBdt,
    required this.recordedDate,
    this.notes,
    this.target = FeedTarget.animal,
  });

  final String? farmRef;
  final String? animalId;
  final String? batchId;
  final String? batchName;
  final FeedType feedType;
  final double amount;
  final FeedUnit unit;
  final double? costBdt;
  final DateTime recordedDate;
  final String? notes;
  final FeedTarget target;

  Map<String, dynamic> toCreateJson() => {
    if (farmRef != null && farmRef!.isNotEmpty) 'farmRef': farmRef,
    if (target == FeedTarget.animal && animalId != null) 'animalId': animalId,
    if (target == FeedTarget.group && batchId != null) 'batchId': batchId,
    if (target == FeedTarget.group && batchName != null) 'batchName': batchName,
    'feedType': feedType.apiValue,
    'amount': amount,
    'unit': unit.apiValue,
    if (costBdt != null) 'costBdt': costBdt,
    'recordedDate': _dateOnly(recordedDate),
    if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
  };

  Map<String, dynamic> toPatchJson() => toCreateJson();

  Map<String, dynamic> toDraftJson() => {
    'farmRef': farmRef,
    'animalId': animalId,
    'batchId': batchId,
    'batchName': batchName,
    'feedType': feedType.apiValue,
    'amount': amount,
    'unit': unit.apiValue,
    'costBdt': costBdt,
    'recordedDate': _dateOnly(recordedDate),
    'notes': notes,
    'target': target.name,
  };

  factory FeedInput.fromDraftJson(Map<String, dynamic> json) {
    return FeedInput(
      farmRef: json['farmRef'] as String?,
      animalId: json['animalId'] as String?,
      batchId: json['batchId'] as String?,
      batchName: json['batchName'] as String?,
      feedType: FeedTypeApi.fromApi(json['feedType'] as String? ?? 'OTHER'),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      unit: FeedUnitApi.fromApi(json['unit'] as String? ?? 'KG'),
      costBdt: (json['costBdt'] as num?)?.toDouble(),
      recordedDate:
          DateTime.tryParse(json['recordedDate'] as String? ?? '') ??
          DateTime.now(),
      notes: json['notes'] as String?,
      target: json['target'] == 'group' ? FeedTarget.group : FeedTarget.animal,
    );
  }
}

class FeedPageResult {
  const FeedPageResult({
    required this.records,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
    this.fromCache = false,
    this.pendingSyncCount = 0,
  });

  final List<FeedRecord> records;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;
  final bool fromCache;
  final int pendingSyncCount;

  FeedPageResult copyWith({
    List<FeedRecord>? records,
    bool? fromCache,
    int? pendingSyncCount,
  }) {
    return FeedPageResult(
      records: records ?? this.records,
      total: total,
      page: page,
      limit: limit,
      hasMore: hasMore,
      fromCache: fromCache ?? this.fromCache,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
    );
  }
}

enum FeedTargetFilter { all, animal, group }

class FeedCostBucket {
  const FeedCostBucket({
    required this.label,
    required this.costBdt,
    required this.amount,
  });

  final String label;
  final double costBdt;
  final double amount;

  factory FeedCostBucket.fromJson(
    Map<String, dynamic> json, {
    required String labelKey,
  }) {
    return FeedCostBucket(
      label: json[labelKey] as String? ?? '',
      costBdt: (json['costBdt'] as num?)?.toDouble() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class FeedAnimalCost {
  const FeedAnimalCost({
    required this.animalId,
    required this.animalName,
    required this.costBdt,
    required this.amount,
  });

  final String animalId;
  final String animalName;
  final double costBdt;
  final double amount;

  factory FeedAnimalCost.fromJson(Map<String, dynamic> json) {
    return FeedAnimalCost(
      animalId: json['animalId'] as String,
      animalName: json['animalName'] as String? ?? '',
      costBdt: (json['costBdt'] as num?)?.toDouble() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class FeedCostData {
  const FeedCostData({
    required this.from,
    required this.to,
    required this.totalCostBdt,
    required this.totalAmount,
    required this.daily,
    required this.weekly,
    required this.monthly,
    required this.byAnimal,
    this.fromCache = false,
  });

  final String from;
  final String to;
  final double totalCostBdt;
  final double totalAmount;
  final List<FeedCostBucket> daily;
  final List<FeedCostBucket> weekly;
  final List<FeedCostBucket> monthly;
  final List<FeedAnimalCost> byAnimal;
  final bool fromCache;

  factory FeedCostData.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
  }) {
    List<FeedCostBucket> mapBuckets(String key, String labelKey) {
      return (json[key] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => FeedCostBucket.fromJson(e, labelKey: labelKey))
          .toList();
    }

    return FeedCostData(
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      totalCostBdt: (json['totalCostBdt'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      daily: mapBuckets('daily', 'date'),
      weekly: mapBuckets('weekly', 'weekStart'),
      monthly: mapBuckets('monthly', 'month'),
      byAnimal: (json['byAnimal'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(FeedAnimalCost.fromJson)
          .toList(),
      fromCache: fromCache,
    );
  }
}

class FeedTypeBreakdown {
  const FeedTypeBreakdown({
    required this.feedType,
    required this.costBdt,
    required this.amount,
    required this.count,
  });

  final String feedType;
  final double costBdt;
  final double amount;
  final int count;

  factory FeedTypeBreakdown.fromJson(Map<String, dynamic> json) {
    return FeedTypeBreakdown(
      feedType: json['feedType'] as String? ?? '',
      costBdt: (json['costBdt'] as num?)?.toDouble() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      count: json['count'] as int? ?? 0,
    );
  }
}

class FeedTrendPoint {
  const FeedTrendPoint({
    required this.date,
    required this.amount,
    required this.costBdt,
  });

  final String date;
  final double amount;
  final double costBdt;

  factory FeedTrendPoint.fromJson(Map<String, dynamic> json) {
    return FeedTrendPoint(
      date: json['date'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      costBdt: (json['costBdt'] as num?)?.toDouble() ?? 0,
    );
  }
}

class FeedEfficiency {
  const FeedEfficiency({
    required this.totalCostBdt,
    required this.totalAmount,
    required this.costPerKg,
    required this.costPerAnimal,
    required this.avgCostPerRecord,
    required this.activeAnimals,
  });

  final double totalCostBdt;
  final double totalAmount;
  final double costPerKg;
  final double costPerAnimal;
  final double avgCostPerRecord;
  final int activeAnimals;

  factory FeedEfficiency.fromJson(Map<String, dynamic> json) {
    return FeedEfficiency(
      totalCostBdt: (json['totalCostBdt'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      costPerKg: (json['costPerKg'] as num?)?.toDouble() ?? 0,
      costPerAnimal: (json['costPerAnimal'] as num?)?.toDouble() ?? 0,
      avgCostPerRecord: (json['avgCostPerRecord'] as num?)?.toDouble() ?? 0,
      activeAnimals: json['activeAnimals'] as int? ?? 0,
    );
  }
}

class FeedAnalyticsData {
  const FeedAnalyticsData({
    required this.from,
    required this.to,
    required this.costBreakdown,
    required this.consumptionTrend,
    required this.efficiency,
    this.fromCache = false,
  });

  final String from;
  final String to;
  final List<FeedTypeBreakdown> costBreakdown;
  final List<FeedTrendPoint> consumptionTrend;
  final FeedEfficiency efficiency;
  final bool fromCache;

  factory FeedAnalyticsData.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
  }) {
    return FeedAnalyticsData(
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      costBreakdown: (json['costBreakdown'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(FeedTypeBreakdown.fromJson)
          .toList(),
      consumptionTrend: (json['consumptionTrend'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(FeedTrendPoint.fromJson)
          .toList(),
      efficiency: FeedEfficiency.fromJson(
        json['efficiency'] as Map<String, dynamic>? ?? {},
      ),
      fromCache: fromCache,
    );
  }
}
