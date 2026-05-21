/// Local conversation model for offline-first AI chat UI.
class AiConversationModel {
  AiConversationModel({
    required this.sessionId,
    required this.messages,
    this.caseId,
    this.locale = 'bn',
    this.pendingDraft,
  });

  final String sessionId;
  final String? caseId;
  final String locale;
  final List<AiConversationMessage> messages;
  final String? pendingDraft;

  AiConversationModel copyWith({
    List<AiConversationMessage>? messages,
    String? pendingDraft,
  }) {
    return AiConversationModel(
      sessionId: sessionId,
      caseId: caseId,
      locale: locale,
      messages: messages ?? this.messages,
      pendingDraft: pendingDraft,
    );
  }
}

class AiConversationMessage {
  const AiConversationMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.refused = false,
  });

  final String id;
  final String role;
  final String content;
  final DateTime createdAt;
  final bool refused;
}

abstract class AiDraftContract {
  static const boxName = 'ai_chat_draft_v1';

  static String draftKey(String sessionId) => 'draft:$sessionId';

  Future<void> saveDraft(String sessionId, String text);

  Future<String?> readDraft(String sessionId);

  Future<void> clearDraft(String sessionId);
}
