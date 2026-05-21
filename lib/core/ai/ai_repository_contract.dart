import 'ai_dto.dart';

abstract class AiRepositoryContract {
  Future<AiChatResponseDto> chat({
    required String message,
    String? sessionId,
    String? caseId,
    String locale = 'bn',
  });

  Future<AiTriageResponseDto> triage({
    required List<String> symptoms,
    String? sessionId,
    String? caseId,
    String? historySummary,
    String locale = 'bn',
  });

  Future<List<AiMemoryEntryDto>> listMemory({String? kind, String? key});

  Future<int> deleteMemory({String? kind, String? key, bool all = false});

  Future<AiEscalationDto> escalate({
    required String reason,
    String? sessionId,
    String? caseId,
    String? handoffNote,
  });
}

abstract class AiApiPaths {
  static const chat = '/api/ai/chat';
  static const triage = '/api/ai/triage';
  static const memory = '/api/ai/memory';
  static const escalate = '/api/ai/escalate';
}
