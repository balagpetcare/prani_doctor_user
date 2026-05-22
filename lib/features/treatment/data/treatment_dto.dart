enum TreatmentStatus { active, completed, cancelled }

extension TreatmentStatusApi on TreatmentStatus {
  String get apiValue => name.toUpperCase();

  static TreatmentStatus fromApi(String value) {
    return TreatmentStatus.values.firstWhere(
      (s) => s.apiValue == value.toUpperCase(),
      orElse: () => TreatmentStatus.active,
    );
  }
}

class MedicineItem {
  const MedicineItem({
    required this.name,
    required this.dosage,
    this.frequency,
    this.durationDays,
  });

  final String name;
  final String dosage;
  final String? frequency;
  final int? durationDays;

  factory MedicineItem.fromJson(Map<String, dynamic> json) {
    return MedicineItem(
      name: json['name'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      frequency: json['frequency'] as String?,
      durationDays: json['durationDays'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'dosage': dosage,
        if (frequency != null) 'frequency': frequency,
        if (durationDays != null) 'durationDays': durationDays,
      };
}

class FarmTreatment {
  const FarmTreatment({
    required this.id,
    required this.customerId,
    this.animalId,
    this.animalName,
    this.farmRef,
    required this.title,
    this.diagnosis,
    this.prescription,
    this.medicines = const [],
    required this.startDate,
    this.endDate,
    required this.status,
    this.notes,
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
  final String title;
  final String? diagnosis;
  final String? prescription;
  final List<MedicineItem> medicines;
  final DateTime startDate;
  final DateTime? endDate;
  final TreatmentStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool pendingSync;
  final bool fromCache;

  String get targetLabel => animalName ?? animalId ?? '—';

  FarmTreatment copyWith({
    String? farmRef,
    String? animalId,
    String? animalName,
    String? title,
    String? diagnosis,
    String? prescription,
    List<MedicineItem>? medicines,
    DateTime? startDate,
    DateTime? endDate,
    TreatmentStatus? status,
    String? notes,
    bool? pendingSync,
    bool? fromCache,
    DateTime? updatedAt,
  }) {
    return FarmTreatment(
      id: id,
      customerId: customerId,
      farmRef: farmRef ?? this.farmRef,
      animalId: animalId ?? this.animalId,
      animalName: animalName ?? this.animalName,
      title: title ?? this.title,
      diagnosis: diagnosis ?? this.diagnosis,
      prescription: prescription ?? this.prescription,
      medicines: medicines ?? this.medicines,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingSync: pendingSync ?? this.pendingSync,
      fromCache: fromCache ?? this.fromCache,
    );
  }

  factory FarmTreatment.fromJson(Map<String, dynamic> json, {bool fromCache = false, bool pendingSync = false}) {
    return FarmTreatment(
      id: json['id'] as String,
      customerId: json['customerId'] as String? ?? '',
      animalId: json['animalId'] as String?,
      animalName: json['animalName'] as String?,
      farmRef: json['farmRef'] as String?,
      title: json['title'] as String? ?? '',
      diagnosis: json['diagnosis'] as String?,
      prescription: json['prescription'] as String?,
      medicines: (json['medicines'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(MedicineItem.fromJson)
          .toList(),
      startDate: DateTime.tryParse(json['startDate'] as String? ?? '') ?? DateTime.now(),
      endDate: json['endDate'] == null ? null : DateTime.tryParse(json['endDate'] as String),
      status: TreatmentStatusApi.fromApi(json['status'] as String? ?? 'ACTIVE'),
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
        if (animalId != null) 'animalId': animalId,
        if (animalName != null) 'animalName': animalName,
        if (farmRef != null) 'farmRef': farmRef,
        'title': title,
        if (diagnosis != null) 'diagnosis': diagnosis,
        if (prescription != null) 'prescription': prescription,
        'medicines': medicines.map((m) => m.toJson()).toList(),
        'startDate': _dateOnly(startDate),
        if (endDate != null) 'endDate': _dateOnly(endDate!),
        'status': status.apiValue,
        if (notes != null) 'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'pendingSync': pendingSync,
      };
}

String _dateOnly(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class TreatmentInput {
  const TreatmentInput({
    this.farmRef,
    this.animalId,
    required this.title,
    this.diagnosis,
    this.prescription,
    this.medicines = const [],
    required this.startDate,
    this.endDate,
    this.status = TreatmentStatus.active,
    this.notes,
  });

  final String? farmRef;
  final String? animalId;
  final String title;
  final String? diagnosis;
  final String? prescription;
  final List<MedicineItem> medicines;
  final DateTime startDate;
  final DateTime? endDate;
  final TreatmentStatus status;
  final String? notes;

  Map<String, dynamic> toCreateJson() => {
        if (farmRef != null && farmRef!.isNotEmpty) 'farmRef': farmRef,
        if (animalId != null && animalId!.isNotEmpty) 'animalId': animalId,
        'title': title.trim(),
        if (diagnosis != null && diagnosis!.trim().isNotEmpty) 'diagnosis': diagnosis!.trim(),
        if (prescription != null && prescription!.trim().isNotEmpty) 'prescription': prescription!.trim(),
        if (medicines.isNotEmpty) 'medicines': medicines.map((m) => m.toJson()).toList(),
        'startDate': _dateOnly(startDate),
        if (endDate != null) 'endDate': _dateOnly(endDate!),
        'status': status.apiValue,
        if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      };

  Map<String, dynamic> toPatchJson() => toCreateJson();

  Map<String, dynamic> toDraftJson() => {
        'farmRef': farmRef,
        'animalId': animalId,
        'title': title,
        'diagnosis': diagnosis,
        'prescription': prescription,
        'medicines': medicines.map((m) => m.toJson()).toList(),
        'startDate': _dateOnly(startDate),
        'endDate': endDate == null ? null : _dateOnly(endDate!),
        'status': status.apiValue,
        'notes': notes,
      };

  factory TreatmentInput.fromDraftJson(Map<String, dynamic> json) {
    return TreatmentInput(
      farmRef: json['farmRef'] as String?,
      animalId: json['animalId'] as String?,
      title: json['title'] as String? ?? '',
      diagnosis: json['diagnosis'] as String?,
      prescription: json['prescription'] as String?,
      medicines: (json['medicines'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(MedicineItem.fromJson)
          .toList(),
      startDate: DateTime.tryParse(json['startDate'] as String? ?? '') ?? DateTime.now(),
      endDate: json['endDate'] == null ? null : DateTime.tryParse(json['endDate'] as String),
      status: TreatmentStatusApi.fromApi(json['status'] as String? ?? 'ACTIVE'),
      notes: json['notes'] as String?,
    );
  }
}

class TreatmentPageResult {
  const TreatmentPageResult({
    required this.records,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
    this.fromCache = false,
  });

  final List<FarmTreatment> records;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;
  final bool fromCache;
}

class PrescriptionData {
  const PrescriptionData({
    required this.treatmentId,
    this.prescription,
    required this.medicines,
    this.fromCache = false,
  });

  final String treatmentId;
  final String? prescription;
  final List<MedicineItem> medicines;
  final bool fromCache;
}
