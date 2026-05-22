abstract final class AiApiPaths {
  AiApiPaths._();

  static const chat = '/api/ai/chat';
  static const triage = '/api/ai/triage';
  static const history = '/api/ai/history';
  static const escalate = '/api/ai/escalate';
  static const memory = '/api/ai/memory';
}

abstract final class VoiceApiPaths {
  VoiceApiPaths._();

  static const stt = '/api/voice/stt';
  static const chat = '/api/voice/chat';
  static const session = '/api/voice/session';
}
