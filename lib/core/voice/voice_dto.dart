class VoiceSttResponseDto {
  const VoiceSttResponseDto({
    required this.sessionId,
    required this.transcriptId,
    required this.normalizedText,
    required this.confidence,
    required this.partial,
    required this.retrySuggested,
    required this.retryCount,
    this.fallbackHint,
  });

  final String sessionId;
  final String transcriptId;
  final String normalizedText;
  final double confidence;
  final bool partial;
  final bool retrySuggested;
  final int retryCount;
  final String? fallbackHint;

  factory VoiceSttResponseDto.fromJson(Map<String, dynamic> json) {
    return VoiceSttResponseDto(
      sessionId: json['sessionId'] as String,
      transcriptId: json['transcriptId'] as String,
      normalizedText: json['normalizedText'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      partial: json['partial'] as bool? ?? false,
      retrySuggested: json['retrySuggested'] as bool? ?? false,
      retryCount: json['retryCount'] as int? ?? 0,
      fallbackHint: json['fallbackHint'] as String?,
    );
  }
}

class VoiceChatResponseDto {
  const VoiceChatResponseDto({
    required this.sessionId,
    required this.responseText,
    required this.transcriptText,
    required this.refused,
    required this.humanRedirect,
    required this.disclaimer,
    required this.interrupted,
    required this.transcriptOnly,
  });

  final String sessionId;
  final String responseText;
  final String transcriptText;
  final bool refused;
  final bool humanRedirect;
  final String disclaimer;
  final bool interrupted;
  final bool transcriptOnly;

  factory VoiceChatResponseDto.fromJson(Map<String, dynamic> json) {
    final audio = json['responseAudio'] as Map<String, dynamic>? ?? {};
    return VoiceChatResponseDto(
      sessionId: json['sessionId'] as String,
      responseText: json['responseText'] as String? ?? '',
      transcriptText: json['transcriptText'] as String? ?? '',
      refused: json['refused'] as bool? ?? false,
      humanRedirect: json['humanRedirect'] as bool? ?? false,
      disclaimer: json['disclaimer'] as String? ?? '',
      interrupted: json['interrupted'] as bool? ?? false,
      transcriptOnly: audio['transcriptOnly'] as bool? ?? true,
    );
  }
}

class VoiceNavigationResponseDto {
  const VoiceNavigationResponseDto({
    required this.action,
    required this.message,
    required this.success,
    this.aliasMatched,
  });

  final String action;
  final String message;
  final bool success;
  final String? aliasMatched;

  factory VoiceNavigationResponseDto.fromJson(Map<String, dynamic> json) {
    return VoiceNavigationResponseDto(
      action: json['action'] as String,
      message: json['message'] as String? ?? '',
      success: json['success'] as bool? ?? false,
      aliasMatched: json['aliasMatched'] as String?,
    );
  }
}

class VoiceSessionDto {
  const VoiceSessionDto({
    required this.sessionId,
    required this.status,
    required this.locale,
    required this.bandwidthMode,
    required this.retryCount,
    required this.transcripts,
  });

  final String sessionId;
  final String status;
  final String locale;
  final String bandwidthMode;
  final int retryCount;
  final List<Map<String, dynamic>> transcripts;

  factory VoiceSessionDto.fromJson(Map<String, dynamic> json) {
    return VoiceSessionDto(
      sessionId: json['sessionId'] as String,
      status: json['status'] as String,
      locale: json['locale'] as String? ?? 'bn',
      bandwidthMode: json['bandwidthMode'] as String? ?? 'FULL',
      retryCount: json['retryCount'] as int? ?? 0,
      transcripts: (json['transcripts'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
  }
}
