enum MilkSession { morning, evening }

extension MilkSessionApi on MilkSession {
  String get apiValue => this == MilkSession.morning ? 'MORNING' : 'EVENING';

  static MilkSession fromApi(String value) {
    return value.toUpperCase() == 'EVENING' ? MilkSession.evening : MilkSession.morning;
  }
}

class MilkRecord {
  const MilkRecord({
    required this.id,
    required this.customerId,
    required this.animalId,
    required this.animalName,
    this.farmRef,
    required this.recordedDate,
    required this.session,
    required this.quantityLiters,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.pendingSync = false,
    this.fromCache = false,
  });

  final String id;
  final String customerId;
  final String animalId;
  final String animalName;
  final String? farmRef;
  final DateTime recordedDate;
  final MilkSession session;
  final double quantityLiters;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool pendingSync;
  final bool fromCache;

  MilkRecord copyWith({
    String? animalId,
    String? animalName,
    String? farmRef,
    DateTime? recordedDate,
    MilkSession? session,
    double? quantityLiters,
    String? notes,
    bool? pendingSync,
    bool? fromCache,
    DateTime? updatedAt,
  }) {
    return MilkRecord(
      id: id,
      customerId: customerId,
      animalId: animalId ?? this.animalId,
      animalName: animalName ?? this.animalName,
      farmRef: farmRef ?? this.farmRef,
      recordedDate: recordedDate ?? this.recordedDate,
      session: session ?? this.session,
      quantityLiters: quantityLiters ?? this.quantityLiters,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingSync: pendingSync ?? this.pendingSync,
      fromCache: fromCache ?? this.fromCache,
    );
  }

  factory MilkRecord.fromJson(Map<String, dynamic> json, {bool fromCache = false, bool pendingSync = false}) {
    return MilkRecord(
      id: json['id'] as String,
      customerId: json['customerId'] as String? ?? '',
      animalId: json['animalId'] as String,
      animalName: json['animalName'] as String? ?? 'Animal',
      farmRef: json['farmRef'] as String?,
      recordedDate: DateTime.tryParse(json['recordedDate'] as String? ?? '') ?? DateTime.now(),
      session: MilkSessionApi.fromApi(json['session'] as String? ?? 'MORNING'),
      quantityLiters: double.tryParse(json['quantityLiters']?.toString() ?? '') ?? 0,
      notes: json['notes'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      pendingSync: pendingSync,
      fromCache: fromCache,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerId': customerId,
        'animalId': animalId,
        'animalName': animalName,
        if (farmRef != null) 'farmRef': farmRef,
        'recordedDate': _dateOnly(recordedDate),
        'session': session.apiValue,
        'quantityLiters': quantityLiters.toStringAsFixed(3),
        if (notes != null) 'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'pendingSync': pendingSync,
      };
}

String _dateOnly(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class MilkInput {
  const MilkInput({
    required this.animalId,
    this.farmRef,
    required this.recordedDate,
    required this.session,
    required this.quantityLiters,
    this.notes,
  });

  final String animalId;
  final String? farmRef;
  final DateTime recordedDate;
  final MilkSession session;
  final double quantityLiters;
  final String? notes;

  Map<String, dynamic> toCreateJson() => {
        'animalId': animalId,
        if (farmRef != null && farmRef!.isNotEmpty) 'farmRef': farmRef,
        'recordedDate': _dateOnly(recordedDate),
        'session': session.apiValue,
        'quantityLiters': quantityLiters,
        if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      };

  Map<String, dynamic> toPatchJson() => toCreateJson();

  Map<String, dynamic> toDraftJson() => {
        'animalId': animalId,
        'farmRef': farmRef,
        'recordedDate': _dateOnly(recordedDate),
        'session': session.apiValue,
        'quantityLiters': quantityLiters,
        'notes': notes,
      };

  factory MilkInput.fromDraftJson(Map<String, dynamic> json) {
    return MilkInput(
      animalId: json['animalId'] as String? ?? '',
      farmRef: json['farmRef'] as String?,
      recordedDate: DateTime.tryParse(json['recordedDate'] as String? ?? '') ?? DateTime.now(),
      session: MilkSessionApi.fromApi(json['session'] as String? ?? 'MORNING'),
      quantityLiters: (json['quantityLiters'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String?,
    );
  }
}

class MilkPageResult {
  const MilkPageResult({
    required this.records,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
    this.fromCache = false,
  });

  final List<MilkRecord> records;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;
  final bool fromCache;

  MilkPageResult copyWith({bool? fromCache, List<MilkRecord>? records}) {
    return MilkPageResult(
      records: records ?? this.records,
      total: total,
      page: page,
      limit: limit,
      hasMore: hasMore,
      fromCache: fromCache ?? this.fromCache,
    );
  }
}

class MilkAnimalSummary {
  const MilkAnimalSummary({
    required this.animalId,
    required this.animalName,
    required this.totalLiters,
    required this.morningLiters,
    required this.eveningLiters,
  });

  final String animalId;
  final String animalName;
  final double totalLiters;
  final double morningLiters;
  final double eveningLiters;

  factory MilkAnimalSummary.fromJson(Map<String, dynamic> json) {
    return MilkAnimalSummary(
      animalId: json['animalId'] as String,
      animalName: json['animalName'] as String? ?? '',
      totalLiters: (json['totalLiters'] as num?)?.toDouble() ?? 0,
      morningLiters: (json['morningLiters'] as num?)?.toDouble() ?? 0,
      eveningLiters: (json['eveningLiters'] as num?)?.toDouble() ?? 0,
    );
  }
}

class MilkDaySummary {
  const MilkDaySummary({
    required this.date,
    required this.totalLiters,
    required this.morningLiters,
    required this.eveningLiters,
  });

  final String date;
  final double totalLiters;
  final double morningLiters;
  final double eveningLiters;

  factory MilkDaySummary.fromJson(Map<String, dynamic> json) {
    return MilkDaySummary(
      date: json['date'] as String,
      totalLiters: (json['totalLiters'] as num?)?.toDouble() ?? 0,
      morningLiters: (json['morningLiters'] as num?)?.toDouble() ?? 0,
      eveningLiters: (json['eveningLiters'] as num?)?.toDouble() ?? 0,
    );
  }
}

class MilkSummary {
  const MilkSummary({
    this.date,
    required this.from,
    required this.to,
    required this.totalLiters,
    required this.morningLiters,
    required this.eveningLiters,
    required this.byAnimal,
    required this.byDay,
    this.fromCache = false,
  });

  final String? date;
  final String from;
  final String to;
  final double totalLiters;
  final double morningLiters;
  final double eveningLiters;
  final List<MilkAnimalSummary> byAnimal;
  final List<MilkDaySummary> byDay;
  final bool fromCache;

  factory MilkSummary.fromJson(Map<String, dynamic> json, {bool fromCache = false}) {
    return MilkSummary(
      date: json['date'] as String?,
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      totalLiters: (json['totalLiters'] as num?)?.toDouble() ?? 0,
      morningLiters: (json['morningLiters'] as num?)?.toDouble() ?? 0,
      eveningLiters: (json['eveningLiters'] as num?)?.toDouble() ?? 0,
      byAnimal: (json['byAnimal'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(MilkAnimalSummary.fromJson)
          .toList(),
      byDay: (json['byDay'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(MilkDaySummary.fromJson)
          .toList(),
      fromCache: fromCache,
    );
  }
}

class MilkDailyPoint {
  const MilkDailyPoint({
    required this.date,
    required this.totalLiters,
    required this.morningLiters,
    required this.eveningLiters,
  });

  final String date;
  final double totalLiters;
  final double morningLiters;
  final double eveningLiters;

  factory MilkDailyPoint.fromJson(Map<String, dynamic> json) {
    return MilkDailyPoint(
      date: json['date'] as String,
      totalLiters: (json['totalLiters'] as num?)?.toDouble() ?? 0,
      morningLiters: (json['morningLiters'] as num?)?.toDouble() ?? 0,
      eveningLiters: (json['eveningLiters'] as num?)?.toDouble() ?? 0,
    );
  }
}

class MilkTrendPoint {
  const MilkTrendPoint({required this.label, required this.totalLiters});

  final String label;
  final double totalLiters;
}

class MilkChartsData {
  const MilkChartsData({
    required this.from,
    required this.to,
    required this.dailyProduction,
    required this.weeklyTrend,
    required this.monthlyTrend,
    required this.morningLiters,
    required this.eveningLiters,
    this.fromCache = false,
  });

  final String from;
  final String to;
  final List<MilkDailyPoint> dailyProduction;
  final List<MilkTrendPoint> weeklyTrend;
  final List<MilkTrendPoint> monthlyTrend;
  final double morningLiters;
  final double eveningLiters;
  final bool fromCache;

  factory MilkChartsData.fromJson(Map<String, dynamic> json, {bool fromCache = false}) {
    final sessionSplit = json['sessionSplit'] as Map<String, dynamic>? ?? {};
    return MilkChartsData(
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      dailyProduction: (json['dailyProduction'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(MilkDailyPoint.fromJson)
          .toList(),
      weeklyTrend: (json['weeklyTrend'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(
            (e) => MilkTrendPoint(
              label: e['weekStart'] as String? ?? '',
              totalLiters: (e['totalLiters'] as num?)?.toDouble() ?? 0,
            ),
          )
          .toList(),
      monthlyTrend: (json['monthlyTrend'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(
            (e) => MilkTrendPoint(
              label: e['month'] as String? ?? '',
              totalLiters: (e['totalLiters'] as num?)?.toDouble() ?? 0,
            ),
          )
          .toList(),
      morningLiters: (sessionSplit['morning'] as num?)?.toDouble() ?? 0,
      eveningLiters: (sessionSplit['evening'] as num?)?.toDouble() ?? 0,
      fromCache: fromCache,
    );
  }
}
