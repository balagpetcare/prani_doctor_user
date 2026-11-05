import 'animal_weight_method.dart';

class AnimalWeightCaptureDraft {
  const AnimalWeightCaptureDraft({
    this.method,
    this.heartGirthCm,
    this.bodyLengthCm,
    this.tapeEstimatedKg,
    this.scaleWeightKg,
    this.scalePhotoLocalPath,
    this.scalePhotoUrl,
    this.aiLocalPaths = const [],
    this.aiUploadIds = const [],
    this.aiJobId,
    this.aiResultKg,
    this.aiConfidence,
    this.aiDisclaimerAck = false,
    this.clientMeasurementId,
  });

  final AnimalWeightMethod? method;
  final double? heartGirthCm;
  final double? bodyLengthCm;
  final double? tapeEstimatedKg;
  final double? scaleWeightKg;
  final String? scalePhotoLocalPath;
  final String? scalePhotoUrl;
  final List<String> aiLocalPaths;
  final List<String> aiUploadIds;
  final String? aiJobId;
  final double? aiResultKg;
  final double? aiConfidence;
  final bool aiDisclaimerAck;
  final String? clientMeasurementId;

  bool get hasCapture {
    if (method == null) return false;
    switch (method!) {
      case AnimalWeightMethod.tape:
        return heartGirthCm != null && bodyLengthCm != null;
      case AnimalWeightMethod.scale:
        return scaleWeightKg != null && scaleWeightKg! > 0;
      case AnimalWeightMethod.aiCamera:
        return aiDisclaimerAck &&
            (aiUploadIds.isNotEmpty || aiLocalPaths.isNotEmpty);
    }
  }

  double? get resolvedWeightKg {
    switch (method) {
      case AnimalWeightMethod.tape:
        return tapeEstimatedKg;
      case AnimalWeightMethod.scale:
        return scaleWeightKg;
      case AnimalWeightMethod.aiCamera:
        return aiResultKg;
      case null:
        return null;
    }
  }

  Map<String, dynamic> toDraftJson() => {
    if (method != null) 'method': method!.apiValue,
    if (heartGirthCm != null) 'heartGirthCm': heartGirthCm,
    if (bodyLengthCm != null) 'bodyLengthCm': bodyLengthCm,
    if (tapeEstimatedKg != null) 'tapeEstimatedKg': tapeEstimatedKg,
    if (scaleWeightKg != null) 'scaleWeightKg': scaleWeightKg,
    if (scalePhotoLocalPath != null) 'scalePhotoLocalPath': scalePhotoLocalPath,
    if (scalePhotoUrl != null) 'scalePhotoUrl': scalePhotoUrl,
    'aiLocalPaths': aiLocalPaths,
    'aiUploadIds': aiUploadIds,
    if (aiJobId != null) 'aiJobId': aiJobId,
    if (aiResultKg != null) 'aiResultKg': aiResultKg,
    if (aiConfidence != null) 'aiConfidence': aiConfidence,
    'aiDisclaimerAck': aiDisclaimerAck,
    if (clientMeasurementId != null) 'clientMeasurementId': clientMeasurementId,
  };

  factory AnimalWeightCaptureDraft.fromDraftJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return const AnimalWeightCaptureDraft();
    return AnimalWeightCaptureDraft(
      method: AnimalWeightMethodX.fromApi(json['method'] as String?),
      heartGirthCm: _dbl(json['heartGirthCm']),
      bodyLengthCm: _dbl(json['bodyLengthCm']),
      tapeEstimatedKg: _dbl(json['tapeEstimatedKg']),
      scaleWeightKg: _dbl(json['scaleWeightKg']),
      scalePhotoLocalPath: json['scalePhotoLocalPath'] as String?,
      scalePhotoUrl: json['scalePhotoUrl'] as String?,
      aiLocalPaths: (json['aiLocalPaths'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      aiUploadIds: (json['aiUploadIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      aiJobId: json['aiJobId'] as String?,
      aiResultKg: _dbl(json['aiResultKg']),
      aiConfidence: _dbl(json['aiConfidence']),
      aiDisclaimerAck: json['aiDisclaimerAck'] as bool? ?? false,
      clientMeasurementId: json['clientMeasurementId'] as String?,
    );
  }

  Map<String, dynamic>? toWeightCaptureJson() {
    if (method == null) return null;
    final clientId =
        clientMeasurementId ?? 'awm-${DateTime.now().millisecondsSinceEpoch}';
    switch (method!) {
      case AnimalWeightMethod.tape:
        if (heartGirthCm == null || bodyLengthCm == null) return null;
        return {
          'method': 'TAPE',
          'heartGirthCm': heartGirthCm,
          'bodyLengthCm': bodyLengthCm,
          'clientMeasurementId': clientId,
        };
      case AnimalWeightMethod.scale:
        if (scaleWeightKg == null) return null;
        return {
          'method': 'SCALE',
          'weightKg': scaleWeightKg,
          if (scalePhotoUrl != null && scalePhotoUrl!.isNotEmpty)
            'scalePhotoUrl': scalePhotoUrl,
          'clientMeasurementId': clientId,
        };
      case AnimalWeightMethod.aiCamera:
        if (!aiDisclaimerAck) return null;
        if (aiUploadIds.isEmpty) return null;
        return {
          'method': 'AI_CAMERA',
          'uploadIds': aiUploadIds,
          'aiDisclaimerAck': true,
          'clientMeasurementId': clientId,
        };
    }
  }

  static double? _dbl(dynamic v) {
    if (v == null) return null;
    return double.tryParse(v.toString());
  }
}
