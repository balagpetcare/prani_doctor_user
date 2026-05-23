enum HealthEventType { symptom, diagnosis, disease, checkup, treatmentRef }

extension HealthEventTypeApi on HealthEventType {
  String get apiValue => switch (this) {
    HealthEventType.symptom => 'SYMPTOM',
    HealthEventType.diagnosis => 'DIAGNOSIS',
    HealthEventType.disease => 'DISEASE',
    HealthEventType.checkup => 'CHECKUP',
    HealthEventType.treatmentRef => 'TREATMENT_REF',
  };

  static HealthEventType fromApi(String value) {
    return HealthEventType.values.firstWhere(
      (t) => t.apiValue == value.toUpperCase(),
      orElse: () => HealthEventType.symptom,
    );
  }
}

class HealthEvent {
  const HealthEvent({
    required this.id,
    required this.customerId,
    this.animalId,
    this.animalName,
    this.farmRef,
    required this.eventType,
    required this.title,
    this.symptoms,
    this.diagnosis,
    this.diseaseName,
    this.treatmentRefId,
    this.vaccineRefId,
    this.notes,
    required this.recordedDate,
    required this.createdAt,
    required this.updatedAt,
    this.pendingSync = false,
    this.fromCache = false,
  });

  final String id;
  final String customerId;
  final String? animalId;
  final String? animalName;
  final String? farmRef;
  final HealthEventType eventType;
  final String title;
  final String? symptoms;
  final String? diagnosis;
  final String? diseaseName;
  final String? treatmentRefId;
  final String? vaccineRefId;
  final String? notes;
  final DateTime recordedDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool pendingSync;
  final bool fromCache;

  String get targetLabel => animalName ?? animalId ?? '—';

  HealthEvent copyWith({
    String? farmRef,
    String? animalId,
    String? animalName,
    HealthEventType? eventType,
    String? title,
    String? symptoms,
    String? diagnosis,
    String? diseaseName,
    String? treatmentRefId,
    String? vaccineRefId,
    String? notes,
    DateTime? recordedDate,
    bool? pendingSync,
    bool? fromCache,
    DateTime? updatedAt,
  }) {
    return HealthEvent(
      id: id,
      customerId: customerId,
      farmRef: farmRef ?? this.farmRef,
      animalId: animalId ?? this.animalId,
      animalName: animalName ?? this.animalName,
      eventType: eventType ?? this.eventType,
      title: title ?? this.title,
      symptoms: symptoms ?? this.symptoms,
      diagnosis: diagnosis ?? this.diagnosis,
      diseaseName: diseaseName ?? this.diseaseName,
      treatmentRefId: treatmentRefId ?? this.treatmentRefId,
      vaccineRefId: vaccineRefId ?? this.vaccineRefId,
      notes: notes ?? this.notes,
      recordedDate: recordedDate ?? this.recordedDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingSync: pendingSync ?? this.pendingSync,
      fromCache: fromCache ?? this.fromCache,
    );
  }

  factory HealthEvent.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
    bool pendingSync = false,
  }) {
    return HealthEvent(
      id: json['id'] as String,
      customerId: json['customerId'] as String? ?? '',
      animalId: json['animalId'] as String?,
      animalName: json['animalName'] as String?,
      farmRef: json['farmRef'] as String?,
      eventType: HealthEventTypeApi.fromApi(
        json['eventType'] as String? ?? 'SYMPTOM',
      ),
      title: json['title'] as String? ?? '',
      symptoms: json['symptoms'] as String?,
      diagnosis: json['diagnosis'] as String?,
      diseaseName: json['diseaseName'] as String?,
      treatmentRefId: json['treatmentRefId'] as String?,
      vaccineRefId: json['vaccineRefId'] as String?,
      notes: json['notes'] as String?,
      recordedDate:
          DateTime.tryParse(json['recordedDate'] as String? ?? '') ??
          DateTime.now(),
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
    if (animalId != null) 'animalId': animalId,
    if (animalName != null) 'animalName': animalName,
    if (farmRef != null) 'farmRef': farmRef,
    'eventType': eventType.apiValue,
    'title': title,
    if (symptoms != null) 'symptoms': symptoms,
    if (diagnosis != null) 'diagnosis': diagnosis,
    if (diseaseName != null) 'diseaseName': diseaseName,
    if (treatmentRefId != null) 'treatmentRefId': treatmentRefId,
    if (vaccineRefId != null) 'vaccineRefId': vaccineRefId,
    if (notes != null) 'notes': notes,
    'recordedDate': _dateOnly(recordedDate),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'pendingSync': pendingSync,
  };
}

String _dateOnly(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class HealthInput {
  const HealthInput({
    this.farmRef,
    this.animalId,
    required this.eventType,
    required this.title,
    this.symptoms,
    this.diagnosis,
    this.diseaseName,
    this.treatmentRefId,
    this.vaccineRefId,
    this.notes,
    required this.recordedDate,
  });

  final String? farmRef;
  final String? animalId;
  final HealthEventType eventType;
  final String title;
  final String? symptoms;
  final String? diagnosis;
  final String? diseaseName;
  final String? treatmentRefId;
  final String? vaccineRefId;
  final String? notes;
  final DateTime recordedDate;

  Map<String, dynamic> toCreateJson() => {
    if (farmRef != null && farmRef!.isNotEmpty) 'farmRef': farmRef,
    if (animalId != null && animalId!.isNotEmpty) 'animalId': animalId,
    'eventType': eventType.apiValue,
    'title': title.trim(),
    if (symptoms != null && symptoms!.trim().isNotEmpty)
      'symptoms': symptoms!.trim(),
    if (diagnosis != null && diagnosis!.trim().isNotEmpty)
      'diagnosis': diagnosis!.trim(),
    if (diseaseName != null && diseaseName!.trim().isNotEmpty)
      'diseaseName': diseaseName!.trim(),
    if (treatmentRefId != null && treatmentRefId!.isNotEmpty)
      'treatmentRefId': treatmentRefId,
    if (vaccineRefId != null && vaccineRefId!.isNotEmpty)
      'vaccineRefId': vaccineRefId,
    if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
    'recordedDate': _dateOnly(recordedDate),
  };

  Map<String, dynamic> toPatchJson() => toCreateJson();

  Map<String, dynamic> toDraftJson() => {
    'farmRef': farmRef,
    'animalId': animalId,
    'eventType': eventType.apiValue,
    'title': title,
    'symptoms': symptoms,
    'diagnosis': diagnosis,
    'diseaseName': diseaseName,
    'treatmentRefId': treatmentRefId,
    'vaccineRefId': vaccineRefId,
    'notes': notes,
    'recordedDate': _dateOnly(recordedDate),
  };

  factory HealthInput.fromDraftJson(Map<String, dynamic> json) {
    return HealthInput(
      farmRef: json['farmRef'] as String?,
      animalId: json['animalId'] as String?,
      eventType: HealthEventTypeApi.fromApi(
        json['eventType'] as String? ?? 'SYMPTOM',
      ),
      title: json['title'] as String? ?? '',
      symptoms: json['symptoms'] as String?,
      diagnosis: json['diagnosis'] as String?,
      diseaseName: json['diseaseName'] as String?,
      treatmentRefId: json['treatmentRefId'] as String?,
      vaccineRefId: json['vaccineRefId'] as String?,
      notes: json['notes'] as String?,
      recordedDate:
          DateTime.tryParse(json['recordedDate'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class HealthPageResult {
  const HealthPageResult({
    required this.records,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
    this.pendingSyncCount = 0,
    this.fromCache = false,
  });

  final List<HealthEvent> records;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;
  final int pendingSyncCount;
  final bool fromCache;

  HealthPageResult copyWith({
    List<HealthEvent>? records,
    int? total,
    int? page,
    int? limit,
    bool? hasMore,
    int? pendingSyncCount,
    bool? fromCache,
  }) {
    return HealthPageResult(
      records: records ?? this.records,
      total: total ?? this.total,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      hasMore: hasMore ?? this.hasMore,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      fromCache: fromCache ?? this.fromCache,
    );
  }
}

class HealthTimelineGroup {
  const HealthTimelineGroup({required this.date, required this.events});

  final String date;
  final List<HealthEvent> events;

  factory HealthTimelineGroup.fromJson(Map<String, dynamic> json) {
    return HealthTimelineGroup(
      date: json['date'] as String? ?? '',
      events: (json['events'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(HealthEvent.fromJson)
          .toList(),
    );
  }
}

class HealthTimelineResult {
  const HealthTimelineResult({
    required this.groups,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
    this.fromCache = false,
  });

  final List<HealthTimelineGroup> groups;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;
  final bool fromCache;

  factory HealthTimelineResult.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
  }) {
    return HealthTimelineResult(
      groups: (json['groups'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(HealthTimelineGroup.fromJson)
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      hasMore: json['hasMore'] as bool? ?? false,
      fromCache: fromCache,
    );
  }
}

class HealthSummaryData {
  const HealthSummaryData({
    required this.totalEvents,
    required this.diseaseEvents,
    required this.checkupEvents,
    required this.treatmentEvents,
    required this.pendingSyncCount,
    this.fromCache = false,
  });

  final int totalEvents;
  final int diseaseEvents;
  final int checkupEvents;
  final int treatmentEvents;
  final int pendingSyncCount;
  final bool fromCache;

  static HealthSummaryData fromRecords(
    List<HealthEvent> records, {
    required int total,
    bool fromCache = false,
  }) {
    var disease = 0;
    var checkup = 0;
    var treatment = 0;
    var pending = 0;
    for (final event in records) {
      if (event.pendingSync) pending++;
      switch (event.eventType) {
        case HealthEventType.disease:
        case HealthEventType.diagnosis:
          disease++;
        case HealthEventType.checkup:
          checkup++;
        case HealthEventType.treatmentRef:
          treatment++;
        case HealthEventType.symptom:
          break;
      }
    }
    return HealthSummaryData(
      totalEvents: total,
      diseaseEvents: disease,
      checkupEvents: checkup,
      treatmentEvents: treatment,
      pendingSyncCount: pending,
      fromCache: fromCache,
    );
  }
}

class HealthTypeBreakdown {
  const HealthTypeBreakdown({required this.eventType, required this.count});

  final HealthEventType eventType;
  final int count;
}

class HealthDiseaseBreakdown {
  const HealthDiseaseBreakdown({required this.name, required this.count});

  final String name;
  final int count;
}

class HealthMonthTrend {
  const HealthMonthTrend({required this.month, required this.count});

  final String month;
  final int count;
}

class HealthAnalyticsData {
  const HealthAnalyticsData({
    required this.eventTypeBreakdown,
    required this.diseaseFrequency,
    required this.monthlyTrend,
    this.fromCache = false,
  });

  final List<HealthTypeBreakdown> eventTypeBreakdown;
  final List<HealthDiseaseBreakdown> diseaseFrequency;
  final List<HealthMonthTrend> monthlyTrend;
  final bool fromCache;

  static HealthAnalyticsData fromRecords(
    List<HealthEvent> records, {
    bool fromCache = false,
  }) {
    final typeCounts = <HealthEventType, int>{};
    final diseaseCounts = <String, int>{};
    final monthCounts = <String, int>{};

    for (final event in records) {
      typeCounts[event.eventType] = (typeCounts[event.eventType] ?? 0) + 1;
      final disease = event.diseaseName?.trim();
      if (disease != null && disease.isNotEmpty) {
        diseaseCounts[disease] = (diseaseCounts[disease] ?? 0) + 1;
      }
      final month = event.recordedDate.toIso8601String().substring(0, 7);
      monthCounts[month] = (monthCounts[month] ?? 0) + 1;
    }

    return HealthAnalyticsData(
      eventTypeBreakdown:
          typeCounts.entries
              .map((e) => HealthTypeBreakdown(eventType: e.key, count: e.value))
              .toList()
            ..sort((a, b) => b.count.compareTo(a.count)),
      diseaseFrequency:
          diseaseCounts.entries
              .map((e) => HealthDiseaseBreakdown(name: e.key, count: e.value))
              .toList()
            ..sort((a, b) => b.count.compareTo(a.count)),
      monthlyTrend:
          monthCounts.entries
              .map((e) => HealthMonthTrend(month: e.key, count: e.value))
              .toList()
            ..sort((a, b) => a.month.compareTo(b.month)),
      fromCache: fromCache,
    );
  }
}
