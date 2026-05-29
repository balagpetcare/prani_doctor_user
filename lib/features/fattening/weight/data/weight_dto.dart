enum WeightRecordMethod { scale, tape, estimate, other }

extension WeightRecordMethodX on WeightRecordMethod {
  String get apiValue => name.toUpperCase();

  static WeightRecordMethod fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'TAPE':
        return WeightRecordMethod.tape;
      case 'ESTIMATE':
        return WeightRecordMethod.estimate;
      case 'OTHER':
        return WeightRecordMethod.other;
      default:
        return WeightRecordMethod.scale;
    }
  }
}

class WeightRecord {
  const WeightRecord({
    required this.id,
    required this.animalId,
    required this.batchId,
    required this.weightKg,
    required this.recordedAt,
    required this.recordedOn,
    required this.method,
    this.note,
    this.photoUrl,
    this.animalName,
    required this.createdAt,
    required this.updatedAt,
    this.pendingSync = false,
    this.fromCache = false,
  });

  final String id;
  final String animalId;
  final String batchId;
  final String weightKg;
  final DateTime recordedAt;
  final String recordedOn;
  final WeightRecordMethod method;
  final String? note;
  final String? photoUrl;
  final String? animalName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool pendingSync;
  final bool fromCache;

  factory WeightRecord.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
  }) {
    return WeightRecord(
      id: json['id'] as String,
      animalId: json['animalId'] as String,
      batchId: json['batchId'] as String,
      weightKg: json['weightKg']?.toString() ?? '',
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      recordedOn: json['recordedOn'] as String? ??
          DateTime.parse(json['recordedAt'] as String)
              .toIso8601String()
              .substring(0, 10),
      method: WeightRecordMethodX.fromApi(json['method'] as String?),
      note: json['note'] as String?,
      photoUrl: json['photoUrl'] as String?,
      animalName: json['animalName'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      pendingSync: json['pendingSync'] as bool? ?? false,
      fromCache: fromCache || (json['fromCache'] as bool? ?? false),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'animalId': animalId,
    'batchId': batchId,
    'weightKg': weightKg,
    'recordedAt': recordedAt.toIso8601String(),
    'recordedOn': recordedOn,
    'method': method.apiValue,
    if (note != null) 'note': note,
    if (photoUrl != null) 'photoUrl': photoUrl,
    if (animalName != null) 'animalName': animalName,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'pendingSync': pendingSync,
    'fromCache': fromCache,
  };
}

class AnimalWeightProgress {
  const AnimalWeightProgress({
    required this.animalId,
    required this.animalName,
    this.initialWeightKg,
    this.currentWeightKg,
    this.gainKg,
    required this.recordCount,
    this.lastRecordedOn,
  });

  final String animalId;
  final String animalName;
  final String? initialWeightKg;
  final String? currentWeightKg;
  final String? gainKg;
  final int recordCount;
  final String? lastRecordedOn;

  factory AnimalWeightProgress.fromJson(Map<String, dynamic> json) {
    return AnimalWeightProgress(
      animalId: json['animalId'] as String,
      animalName: json['animalName'] as String,
      initialWeightKg: json['initialWeightKg']?.toString(),
      currentWeightKg: json['currentWeightKg']?.toString(),
      gainKg: json['gainKg']?.toString(),
      recordCount: json['recordCount'] as int? ?? 0,
      lastRecordedOn: json['lastRecordedOn'] as String?,
    );
  }
}

class BatchWeightGrowthPoint {
  const BatchWeightGrowthPoint({
    required this.recordedOn,
    required this.totalWeightKg,
    required this.avgWeightKg,
  });

  final String recordedOn;
  final double totalWeightKg;
  final double avgWeightKg;

  factory BatchWeightGrowthPoint.fromJson(Map<String, dynamic> json) {
    double n(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;
    return BatchWeightGrowthPoint(
      recordedOn: json['recordedOn'] as String,
      totalWeightKg: n(json['totalWeightKg']),
      avgWeightKg: n(json['avgWeightKg']),
    );
  }
}

class BatchWeightProgress {
  const BatchWeightProgress({
    required this.batchId,
    required this.progress,
    required this.growth,
    this.totalGainKg,
    this.avgCurrentWeightKg,
    this.fromCache = false,
  });

  final String batchId;
  final List<AnimalWeightProgress> progress;
  final List<BatchWeightGrowthPoint> growth;
  final double? totalGainKg;
  final double? avgCurrentWeightKg;
  final bool fromCache;

  factory BatchWeightProgress.fromJson(Map<String, dynamic> json) {
    final raw = json['progress'] is Map<String, dynamic>
        ? json['progress'] as Map<String, dynamic>
        : json;
    return BatchWeightProgress(
      batchId: raw['batchId'] as String,
      progress: (raw['progress'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(AnimalWeightProgress.fromJson)
          .toList(),
      growth: (raw['growth'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(BatchWeightGrowthPoint.fromJson)
          .toList(),
      totalGainKg: raw['totalGainKg'] == null
          ? null
          : double.tryParse(raw['totalGainKg'].toString()),
      avgCurrentWeightKg: raw['avgCurrentWeightKg'] == null
          ? null
          : double.tryParse(raw['avgCurrentWeightKg'].toString()),
      fromCache: json['fromCache'] as bool? ?? false,
    );
  }
}

class WeightHistoryResult {
  const WeightHistoryResult({
    required this.records,
    required this.progress,
    required this.growth,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
    this.totalGainKg,
    this.avgCurrentWeightKg,
    this.fromCache = false,
  });

  final List<WeightRecord> records;
  final List<AnimalWeightProgress> progress;
  final List<BatchWeightGrowthPoint> growth;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;
  final double? totalGainKg;
  final double? avgCurrentWeightKg;
  final bool fromCache;
}

class WeightRecordInput {
  const WeightRecordInput({
    required this.animalId,
    required this.batchId,
    required this.weightKg,
    this.recordedAt,
    this.recordedOn,
    this.method = WeightRecordMethod.scale,
    this.note,
    this.photoUrl,
    this.clientRecordId,
  });

  final String animalId;
  final String batchId;
  final double weightKg;
  final DateTime? recordedAt;
  final String? recordedOn;
  final WeightRecordMethod method;
  final String? note;
  final String? photoUrl;
  final String? clientRecordId;

  Map<String, dynamic> toJson() {
    final at = recordedAt ?? DateTime.now();
    final on = recordedOn ??
        '${at.toUtc().year.toString().padLeft(4, '0')}-'
        '${at.toUtc().month.toString().padLeft(2, '0')}-'
        '${at.toUtc().day.toString().padLeft(2, '0')}';
    return {
      'animalId': animalId,
      'batchId': batchId,
      'weightKg': weightKg,
      'recordedAt': at.toUtc().toIso8601String(),
      'recordedOn': on,
      'method': method.apiValue,
      if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
      if (photoUrl != null && photoUrl!.trim().isNotEmpty)
        'photoUrl': photoUrl!.trim(),
      if (clientRecordId != null) 'clientRecordId': clientRecordId,
    };
  }
}
