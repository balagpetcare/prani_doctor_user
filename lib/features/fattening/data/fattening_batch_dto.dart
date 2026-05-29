import '../../animals/data/animal_dto.dart';

enum FatteningBatchStatus { draft, active, completed, archived }

enum FatteningBatchGoalType { normal, qurbani }

extension FatteningBatchGoalTypeX on FatteningBatchGoalType {
  String get apiValue => name.toUpperCase();

  static FatteningBatchGoalType fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'QURBANI':
        return FatteningBatchGoalType.qurbani;
      default:
        return FatteningBatchGoalType.normal;
    }
  }

  bool get isQurbani => this == FatteningBatchGoalType.qurbani;
}

extension FatteningBatchStatusX on FatteningBatchStatus {
  String get apiValue => name.toUpperCase();

  static FatteningBatchStatus fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'ACTIVE':
        return FatteningBatchStatus.active;
      case 'COMPLETED':
        return FatteningBatchStatus.completed;
      case 'ARCHIVED':
        return FatteningBatchStatus.archived;
      default:
        return FatteningBatchStatus.draft;
    }
  }

  bool get isDraft => this == FatteningBatchStatus.draft;
  bool get isActive => this == FatteningBatchStatus.active;
}

class FatteningBatch {
  const FatteningBatch({
    required this.id,
    required this.farmId,
    required this.name,
    this.goalType = FatteningBatchGoalType.normal,
    this.goal,
    this.startDate,
    this.targetDate,
    required this.status,
    this.animalCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.pendingSync = false,
    this.lastSyncError,
    this.fromCache = false,
  });

  final String id;
  final String farmId;
  final String name;
  final FatteningBatchGoalType goalType;
  final String? goal;
  final DateTime? startDate;
  final DateTime? targetDate;
  final FatteningBatchStatus status;
  final int animalCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool pendingSync;
  final String? lastSyncError;
  final bool fromCache;

  FatteningBatch copyWith({
    String? name,
    FatteningBatchGoalType? goalType,
    String? goal,
    DateTime? startDate,
    DateTime? targetDate,
    FatteningBatchStatus? status,
    int? animalCount,
    bool? pendingSync,
    String? lastSyncError,
    bool? fromCache,
    DateTime? updatedAt,
  }) {
    return FatteningBatch(
      id: id,
      farmId: farmId,
      name: name ?? this.name,
      goalType: goalType ?? this.goalType,
      goal: goal ?? this.goal,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      status: status ?? this.status,
      animalCount: animalCount ?? this.animalCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingSync: pendingSync ?? this.pendingSync,
      lastSyncError: lastSyncError,
      fromCache: fromCache ?? this.fromCache,
    );
  }

  factory FatteningBatch.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
  }) {
    return FatteningBatch(
      id: json['id'] as String,
      farmId: json['farmId'] as String,
      name: json['name'] as String,
      goalType: FatteningBatchGoalTypeX.fromApi(json['goalType'] as String?),
      goal: json['goal'] as String?,
      startDate: _parseDate(json['startDate']),
      targetDate: _parseDate(json['targetDate']),
      status: FatteningBatchStatusX.fromApi(json['status'] as String?),
      animalCount: json['animalCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      pendingSync: json['pendingSync'] as bool? ?? false,
      lastSyncError: json['lastSyncError'] as String?,
      fromCache: fromCache || (json['fromCache'] as bool? ?? false),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'farmId': farmId,
    'name': name,
    'goalType': goalType.apiValue,
    if (goal != null) 'goal': goal,
    if (startDate != null) 'startDate': _formatDate(startDate!),
    if (targetDate != null) 'targetDate': _formatDate(targetDate!),
    'status': status.apiValue,
    'animalCount': animalCount,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'pendingSync': pendingSync,
    if (lastSyncError != null) 'lastSyncError': lastSyncError,
    'fromCache': fromCache,
  };
}

class FatteningBatchPageResult {
  const FatteningBatchPageResult({
    required this.batches,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
    this.fromCache = false,
    this.pendingSyncCount = 0,
  });

  final List<FatteningBatch> batches;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;
  final bool fromCache;
  final int pendingSyncCount;
}

class FatteningBatchDetail {
  const FatteningBatchDetail({
    required this.batch,
    required this.animals,
    this.fromCache = false,
  });

  final FatteningBatch batch;
  final List<AnimalProfile> animals;
  final bool fromCache;
}

class FatteningBatchInput {
  const FatteningBatchInput({
    required this.farmId,
    required this.name,
    this.goalType = FatteningBatchGoalType.normal,
    this.goal,
    this.targetDate,
  });

  final String farmId;
  final String name;
  final FatteningBatchGoalType goalType;
  final String? goal;
  final DateTime? targetDate;

  Map<String, dynamic> toCreateJson() => {
    'farmId': farmId,
    'name': name.trim(),
    'goalType': goalType.apiValue,
    if (goal != null && goal!.trim().isNotEmpty) 'goal': goal!.trim(),
    if (targetDate != null) 'targetDate': _formatDate(targetDate!),
  };
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is String && value.isEmpty) return null;
  return DateTime.parse(value as String);
}

String _formatDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
