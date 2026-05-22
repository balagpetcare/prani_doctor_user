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

  factory HealthEvent.fromJson(Map<String, dynamic> json, {bool fromCache = false, bool pendingSync = false}) {
    return HealthEvent(
      id: json['id'] as String,
      customerId: json['customerId'] as String? ?? '',
      animalId: json['animalId'] as String?,
      animalName: json['animalName'] as String?,
      farmRef: json['farmRef'] as String?,
      eventType: HealthEventTypeApi.fromApi(json['eventType'] as String? ?? 'SYMPTOM'),
      title: json['title'] as String? ?? '',
      symptoms: json['symptoms'] as String?,
      diagnosis: json['diagnosis'] as String?,
      diseaseName: json['diseaseName'] as String?,
      treatmentRefId: json['treatmentRefId'] as String?,
      vaccineRefId: json['vaccineRefId'] as String?,
      notes: json['notes'] as String?,
      recordedDate: DateTime.tryParse(json['recordedDate'] as String? ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
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
        if (symptoms != null && symptoms!.trim().isNotEmpty) 'symptoms': symptoms!.trim(),
        if (diagnosis != null && diagnosis!.trim().isNotEmpty) 'diagnosis': diagnosis!.trim(),
        if (diseaseName != null && diseaseName!.trim().isNotEmpty) 'diseaseName': diseaseName!.trim(),
        if (treatmentRefId != null && treatmentRefId!.isNotEmpty) 'treatmentRefId': treatmentRefId,
        if (vaccineRefId != null && vaccineRefId!.isNotEmpty) 'vaccineRefId': vaccineRefId,
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
      eventType: HealthEventTypeApi.fromApi(json['eventType'] as String? ?? 'SYMPTOM'),
      title: json['title'] as String? ?? '',
      symptoms: json['symptoms'] as String?,
      diagnosis: json['diagnosis'] as String?,
      diseaseName: json['diseaseName'] as String?,
      treatmentRefId: json['treatmentRefId'] as String?,
      vaccineRefId: json['vaccineRefId'] as String?,
      notes: json['notes'] as String?,
      recordedDate: DateTime.tryParse(json['recordedDate'] as String? ?? '') ?? DateTime.now(),
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
    this.fromCache = false,
  });

  final List<HealthEvent> records;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;
  final bool fromCache;
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

  factory HealthTimelineResult.fromJson(Map<String, dynamic> json, {bool fromCache = false}) {
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
