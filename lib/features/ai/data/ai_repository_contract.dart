import '../../../core/error/api_result.dart';
import 'ai_dto.dart';

abstract class AiRepositoryContract {
  Future<AiHistoryResult?> readCachedHistory({String? sessionId});

  Future<ApiResult<AiHistoryResult>> getHistory({String? sessionId, bool forceRefresh = false});

  Future<ApiResult<AiChatResponse>> sendMessage(AiSendMessageInput input);

  Future<ApiResult<TriageResultModel>> runTriage(AiTriageInput input);

  Future<ApiResult<void>> clearHistory({String? sessionId});

  Future<ApiResult<int>> syncPending();

  Future<ApiResult<VoiceSttResult>> normalizeVoiceTranscript({
    required String transcript,
    String? sessionId,
    AiLocale locale = AiLocale.bn,
    double confidence = 0.85,
  });
}
