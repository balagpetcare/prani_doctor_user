import 'voice_dto.dart';

abstract class VoiceRepositoryContract {
  Future<VoiceSttResponseDto> stt({
    required String transcript,
    required String mode,
    String? sessionId,
    String? caseId,
    bool partial = false,
    double confidence = 0.75,
    String locale = 'bn',
    Map<String, dynamic>? audioMetadata,
  });

  Future<VoiceChatResponseDto> chat({
    required String sessionId,
    required String transcriptId,
    bool interrupt = false,
    bool resume = false,
    bool lowTokenMode = true,
    String bandwidthMode = 'FULL',
  });

  Future<VoiceNavigationResponseDto> navigation({
    required String sessionId,
    required String utterance,
    String locale = 'bn',
  });

  Future<VoiceSessionDto> getSession(String sessionId);
}

abstract class VoiceApiPaths {
  static const stt = '/api/voice/stt';
  static const chat = '/api/voice/chat';
  static const navigation = '/api/voice/navigation';
  static String session(String sessionId) => '/api/voice/session?sessionId=$sessionId';
}
