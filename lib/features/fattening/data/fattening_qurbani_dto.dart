import 'fattening_batch_dto.dart';

enum QurbaniReadinessStatus {
  notStarted,
  onTrack,
  atRisk,
  ready,
  overdue,
}

extension QurbaniReadinessStatusX on QurbaniReadinessStatus {
  String get apiValue => switch (this) {
    QurbaniReadinessStatus.ready => 'READY',
    QurbaniReadinessStatus.atRisk => 'AT_RISK',
    QurbaniReadinessStatus.overdue => 'OVERDUE',
    QurbaniReadinessStatus.notStarted => 'NOT_STARTED',
    QurbaniReadinessStatus.onTrack => 'ON_TRACK',
  };

  static QurbaniReadinessStatus fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'READY':
        return QurbaniReadinessStatus.ready;
      case 'AT_RISK':
        return QurbaniReadinessStatus.atRisk;
      case 'OVERDUE':
        return QurbaniReadinessStatus.overdue;
      case 'NOT_STARTED':
        return QurbaniReadinessStatus.notStarted;
      default:
        return QurbaniReadinessStatus.onTrack;
    }
  }
}

class QurbaniCountdown {
  const QurbaniCountdown({
    this.targetDate,
    this.daysRemaining,
    this.isPast = false,
    this.label,
  });

  final String? targetDate;
  final int? daysRemaining;
  final bool isPast;
  final String? label;

  factory QurbaniCountdown.fromJson(Map<String, dynamic> json) {
    return QurbaniCountdown(
      targetDate: json['targetDate'] as String?,
      daysRemaining: json['daysRemaining'] as int?,
      isPast: json['isPast'] as bool? ?? false,
      label: json['label'] as String?,
    );
  }
}

class QurbaniReadinessSummary {
  const QurbaniReadinessSummary({
    required this.scorePct,
    required this.status,
    this.weightProgressPct,
    this.timeProgressPct,
    required this.animalCount,
    required this.animalsWithWeights,
  });

  final double scorePct;
  final QurbaniReadinessStatus status;
  final double? weightProgressPct;
  final double? timeProgressPct;
  final int animalCount;
  final int animalsWithWeights;

  factory QurbaniReadinessSummary.fromJson(Map<String, dynamic> json) {
    double? opt(dynamic v) =>
        v == null ? null : double.tryParse(v.toString());
    return QurbaniReadinessSummary(
      scorePct: double.tryParse(json['scorePct']?.toString() ?? '') ?? 0,
      status: QurbaniReadinessStatusX.fromApi(json['status'] as String?),
      weightProgressPct: opt(json['weightProgressPct']),
      timeProgressPct: opt(json['timeProgressPct']),
      animalCount: json['animalCount'] as int? ?? 0,
      animalsWithWeights: json['animalsWithWeights'] as int? ?? 0,
    );
  }
}

class QurbaniAnimalReadiness {
  const QurbaniAnimalReadiness({
    required this.animalId,
    required this.animalName,
    this.initialWeightKg,
    this.currentWeightKg,
    this.gainKg,
    required this.targetWeightKg,
    required this.progressPct,
    required this.recordCount,
  });

  final String animalId;
  final String animalName;
  final String? initialWeightKg;
  final String? currentWeightKg;
  final String? gainKg;
  final double targetWeightKg;
  final double progressPct;
  final int recordCount;

  factory QurbaniAnimalReadiness.fromJson(Map<String, dynamic> json) {
    return QurbaniAnimalReadiness(
      animalId: json['animalId'] as String,
      animalName: json['animalName'] as String,
      initialWeightKg: json['initialWeightKg']?.toString(),
      currentWeightKg: json['currentWeightKg']?.toString(),
      gainKg: json['gainKg']?.toString(),
      targetWeightKg:
          double.tryParse(json['targetWeightKg']?.toString() ?? '') ?? 450,
      progressPct:
          double.tryParse(json['progressPct']?.toString() ?? '') ?? 0,
      recordCount: json['recordCount'] as int? ?? 0,
    );
  }
}

class QurbaniDashboard {
  const QurbaniDashboard({
    required this.batchId,
    required this.goalType,
    required this.countdown,
    required this.readiness,
    required this.animals,
    this.fromCache = false,
  });

  final String batchId;
  final FatteningBatchGoalType goalType;
  final QurbaniCountdown countdown;
  final QurbaniReadinessSummary readiness;
  final List<QurbaniAnimalReadiness> animals;
  final bool fromCache;

  factory QurbaniDashboard.fromJson(Map<String, dynamic> json) {
    final raw = json['dashboard'] as Map<String, dynamic>? ?? json;
    return QurbaniDashboard(
      batchId: raw['batchId'] as String,
      goalType: FatteningBatchGoalTypeX.fromApi(raw['goalType'] as String?),
      countdown: QurbaniCountdown.fromJson(
        raw['countdown'] as Map<String, dynamic>? ?? {},
      ),
      readiness: QurbaniReadinessSummary.fromJson(
        raw['readiness'] as Map<String, dynamic>? ?? {},
      ),
      animals: (raw['animals'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(QurbaniAnimalReadiness.fromJson)
          .toList(),
      fromCache: json['fromCache'] as bool? ?? raw['fromCache'] as bool? ?? false,
    );
  }
}
