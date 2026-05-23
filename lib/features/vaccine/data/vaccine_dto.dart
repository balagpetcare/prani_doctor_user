enum VaccineStatus { scheduled, due, overdue, completed }

extension VaccineStatusApi on VaccineStatus {
  String get apiValue => name.toUpperCase();

  static VaccineStatus fromApi(String value) {
    return VaccineStatus.values.firstWhere(
      (s) => s.apiValue == value.toUpperCase(),
      orElse: () => VaccineStatus.scheduled,
    );
  }
}

class VaccineRecord {
  const VaccineRecord({
    required this.id,
    required this.customerId,
    this.animalId,
    this.animalName,
    this.farmRef,
    required this.vaccineName,
    this.vaccineType,
    required this.scheduledDate,
    this.administeredDate,
    this.nextDueDate,
    required this.status,
    this.batchNumber,
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
  final String vaccineName;
  final String? vaccineType;
  final DateTime scheduledDate;
  final DateTime? administeredDate;
  final DateTime? nextDueDate;
  final VaccineStatus status;
  final String? batchNumber;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool pendingSync;
  final bool fromCache;

  String get targetLabel => animalName ?? animalId ?? '—';

  VaccineRecord copyWith({
    String? farmRef,
    String? animalId,
    String? animalName,
    String? vaccineName,
    String? vaccineType,
    DateTime? scheduledDate,
    DateTime? administeredDate,
    DateTime? nextDueDate,
    VaccineStatus? status,
    String? batchNumber,
    String? notes,
    bool? pendingSync,
    bool? fromCache,
    DateTime? updatedAt,
  }) {
    return VaccineRecord(
      id: id,
      customerId: customerId,
      farmRef: farmRef ?? this.farmRef,
      animalId: animalId ?? this.animalId,
      animalName: animalName ?? this.animalName,
      vaccineName: vaccineName ?? this.vaccineName,
      vaccineType: vaccineType ?? this.vaccineType,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      administeredDate: administeredDate ?? this.administeredDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      status: status ?? this.status,
      batchNumber: batchNumber ?? this.batchNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingSync: pendingSync ?? this.pendingSync,
      fromCache: fromCache ?? this.fromCache,
    );
  }

  factory VaccineRecord.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
    bool pendingSync = false,
  }) {
    return VaccineRecord(
      id: json['id'] as String,
      customerId: json['customerId'] as String? ?? '',
      animalId: json['animalId'] as String?,
      animalName: json['animalName'] as String?,
      farmRef: json['farmRef'] as String?,
      vaccineName: json['vaccineName'] as String? ?? '',
      vaccineType: json['vaccineType'] as String?,
      scheduledDate:
          DateTime.tryParse(json['scheduledDate'] as String? ?? '') ??
          DateTime.now(),
      administeredDate: json['administeredDate'] == null
          ? null
          : DateTime.tryParse(json['administeredDate'] as String),
      nextDueDate: json['nextDueDate'] == null
          ? null
          : DateTime.tryParse(json['nextDueDate'] as String),
      status: VaccineStatusApi.fromApi(
        json['status'] as String? ?? 'SCHEDULED',
      ),
      batchNumber: json['batchNumber'] as String?,
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
    if (animalId != null) 'animalId': animalId,
    if (animalName != null) 'animalName': animalName,
    if (farmRef != null) 'farmRef': farmRef,
    'vaccineName': vaccineName,
    if (vaccineType != null) 'vaccineType': vaccineType,
    'scheduledDate': _dateOnly(scheduledDate),
    if (administeredDate != null)
      'administeredDate': _dateOnly(administeredDate!),
    if (nextDueDate != null) 'nextDueDate': _dateOnly(nextDueDate!),
    'status': status.apiValue,
    if (batchNumber != null) 'batchNumber': batchNumber,
    if (notes != null) 'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'pendingSync': pendingSync,
  };
}

String _dateOnly(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class VaccineInput {
  const VaccineInput({
    this.farmRef,
    this.animalId,
    required this.vaccineName,
    this.vaccineType,
    required this.scheduledDate,
    this.administeredDate,
    this.nextDueDate,
    this.batchNumber,
    this.notes,
  });

  final String? farmRef;
  final String? animalId;
  final String vaccineName;
  final String? vaccineType;
  final DateTime scheduledDate;
  final DateTime? administeredDate;
  final DateTime? nextDueDate;
  final String? batchNumber;
  final String? notes;

  Map<String, dynamic> toCreateJson() => {
    if (farmRef != null && farmRef!.isNotEmpty) 'farmRef': farmRef,
    if (animalId != null && animalId!.isNotEmpty) 'animalId': animalId,
    'vaccineName': vaccineName.trim(),
    if (vaccineType != null && vaccineType!.trim().isNotEmpty)
      'vaccineType': vaccineType!.trim(),
    'scheduledDate': _dateOnly(scheduledDate),
    if (administeredDate != null)
      'administeredDate': _dateOnly(administeredDate!),
    if (nextDueDate != null) 'nextDueDate': _dateOnly(nextDueDate!),
    if (batchNumber != null && batchNumber!.trim().isNotEmpty)
      'batchNumber': batchNumber!.trim(),
    if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
  };

  Map<String, dynamic> toPatchJson() => toCreateJson();

  Map<String, dynamic> toDraftJson() => {
    'farmRef': farmRef,
    'animalId': animalId,
    'vaccineName': vaccineName,
    'vaccineType': vaccineType,
    'scheduledDate': _dateOnly(scheduledDate),
    'administeredDate': administeredDate == null
        ? null
        : _dateOnly(administeredDate!),
    'nextDueDate': nextDueDate == null ? null : _dateOnly(nextDueDate!),
    'batchNumber': batchNumber,
    'notes': notes,
  };

  factory VaccineInput.fromDraftJson(Map<String, dynamic> json) {
    return VaccineInput(
      farmRef: json['farmRef'] as String?,
      animalId: json['animalId'] as String?,
      vaccineName: json['vaccineName'] as String? ?? '',
      vaccineType: json['vaccineType'] as String?,
      scheduledDate:
          DateTime.tryParse(json['scheduledDate'] as String? ?? '') ??
          DateTime.now(),
      administeredDate: json['administeredDate'] == null
          ? null
          : DateTime.tryParse(json['administeredDate'] as String),
      nextDueDate: json['nextDueDate'] == null
          ? null
          : DateTime.tryParse(json['nextDueDate'] as String),
      batchNumber: json['batchNumber'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

class VaccinePageResult {
  const VaccinePageResult({
    required this.records,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
    this.pendingSyncCount = 0,
    this.fromCache = false,
  });

  final List<VaccineRecord> records;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;
  final int pendingSyncCount;
  final bool fromCache;

  VaccinePageResult copyWith({
    List<VaccineRecord>? records,
    int? total,
    int? page,
    int? limit,
    bool? hasMore,
    int? pendingSyncCount,
    bool? fromCache,
  }) {
    return VaccinePageResult(
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

class VaccineRemindersData {
  const VaccineRemindersData({
    required this.overdue,
    required this.upcoming,
    this.nextDue,
    this.fromCache = false,
  });

  final List<VaccineRecord> overdue;
  final List<VaccineRecord> upcoming;
  final VaccineRecord? nextDue;
  final bool fromCache;

  factory VaccineRemindersData.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
  }) {
    final reminders = json['reminders'];
    if (reminders is! Map<String, dynamic>) {
      return const VaccineRemindersData(overdue: [], upcoming: []);
    }
    return VaccineRemindersData(
      overdue: (reminders['overdue'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((j) => VaccineRecord.fromJson(j, fromCache: fromCache))
          .toList(),
      upcoming: (reminders['upcoming'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((j) => VaccineRecord.fromJson(j, fromCache: fromCache))
          .toList(),
      nextDue: reminders['nextDue'] is Map<String, dynamic>
          ? VaccineRecord.fromJson(
              reminders['nextDue'] as Map<String, dynamic>,
              fromCache: fromCache,
            )
          : null,
      fromCache: fromCache,
    );
  }
}

class VaccineSummaryData {
  const VaccineSummaryData({
    required this.completed,
    required this.upcoming,
    required this.overdue,
    required this.pendingSyncCount,
    this.fromCache = false,
  });

  final int completed;
  final int upcoming;
  final int overdue;
  final int pendingSyncCount;
  final bool fromCache;

  static VaccineSummaryData fromSources({
    required List<VaccineRecord> allRecords,
    required VaccineRemindersData reminders,
    bool fromCache = false,
  }) {
    final completed = allRecords
        .where((r) => r.status == VaccineStatus.completed)
        .length;
    final pending = allRecords.where((r) => r.pendingSync).length;
    return VaccineSummaryData(
      completed: completed,
      upcoming: reminders.upcoming.length,
      overdue: reminders.overdue.length,
      pendingSyncCount: pending,
      fromCache: fromCache,
    );
  }
}

class VaccineCalendarDay {
  const VaccineCalendarDay({required this.date, required this.records});

  final DateTime date;
  final List<VaccineRecord> records;
}
