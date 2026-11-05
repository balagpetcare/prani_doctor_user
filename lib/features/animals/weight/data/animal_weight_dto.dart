import 'animal_weight_method.dart';

class AnimalWeightMeasurement {
  const AnimalWeightMeasurement({
    required this.id,
    required this.animalId,
    required this.method,
    required this.weightKg,
    required this.measuredAt,
    required this.measuredOn,
    this.heartGirthCm,
    this.bodyLengthCm,
    this.tapeFormulaId,
    this.scalePhotoUrl,
    this.aiConfidence,
    this.note,
  });

  final String id;
  final String animalId;
  final AnimalWeightMethod method;
  final String weightKg;
  final DateTime measuredAt;
  final String measuredOn;
  final String? heartGirthCm;
  final String? bodyLengthCm;
  final String? tapeFormulaId;
  final String? scalePhotoUrl;
  final String? aiConfidence;
  final String? note;

  factory AnimalWeightMeasurement.fromJson(Map<String, dynamic> json) {
    return AnimalWeightMeasurement(
      id: json['id'] as String,
      animalId: json['animalId'] as String,
      method:
          AnimalWeightMethodX.fromApi(json['method'] as String?) ??
          AnimalWeightMethod.scale,
      weightKg: json['weightKg']?.toString() ?? '',
      measuredAt: DateTime.parse(json['measuredAt'] as String),
      measuredOn: json['measuredOn'] as String? ?? '',
      heartGirthCm: json['heartGirthCm']?.toString(),
      bodyLengthCm: json['bodyLengthCm']?.toString(),
      tapeFormulaId: json['tapeFormulaId'] as String?,
      scalePhotoUrl: json['scalePhotoUrl'] as String?,
      aiConfidence: json['aiConfidence']?.toString(),
      note: json['note'] as String?,
    );
  }
}

class AnimalWeightHistoryResult {
  const AnimalWeightHistoryResult({
    required this.records,
    required this.total,
    required this.page,
    required this.hasMore,
  });

  final List<AnimalWeightMeasurement> records;
  final int total;
  final int page;
  final bool hasMore;

  factory AnimalWeightHistoryResult.fromJson(Map<String, dynamic> json) {
    final raw = json['records'] is List
        ? json['records'] as List
        : (json['data']?['records'] as List?) ?? [];
    return AnimalWeightHistoryResult(
      records: raw
          .whereType<Map<String, dynamic>>()
          .map(AnimalWeightMeasurement.fromJson)
          .toList(),
      total: json['total'] as int? ?? raw.length,
      page: json['page'] as int? ?? 1,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}

class AnimalWeightAiJob {
  const AnimalWeightAiJob({
    required this.id,
    required this.status,
    this.resultWeightKg,
    this.confidence,
    this.errorCode,
  });

  final String id;
  final String status;
  final String? resultWeightKg;
  final String? confidence;
  final String? errorCode;

  bool get isDone =>
      status == 'SUCCEEDED' || status == 'FAILED' || status == 'CANCELLED';

  factory AnimalWeightAiJob.fromJson(Map<String, dynamic> json) {
    final job = json['job'] is Map<String, dynamic>
        ? json['job'] as Map<String, dynamic>
        : json;
    return AnimalWeightAiJob(
      id: job['id'] as String,
      status: job['status'] as String? ?? 'PENDING',
      resultWeightKg: job['resultWeightKg']?.toString(),
      confidence: job['confidence']?.toString(),
      errorCode: job['errorCode'] as String?,
    );
  }
}
