import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_result.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_helpers.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/offline/local_cache_contract.dart';
import '../../../core/offline/network_errors.dart';
import '../../offline/data/local_cache_service.dart';
import '../../offline/data/outbox_item.dart';
import '../../offline/data/outbox_service.dart';
import '../../offline/offline_providers.dart';
import 'ai_api_paths.dart';
import 'ai_dto.dart';
import 'ai_repository_contract.dart';

class AiRepository implements AiRepositoryContract {
  AiRepository(this._dio, this._cache, this._outbox);

  final Dio _dio;
  final LocalCacheService _cache;
  final OutboxService _outbox;

  String _historyKey(String? sessionId) => sessionId == null
      ? LocalCacheContract.aiActiveSessionKey
      : LocalCacheContract.aiConversationKey(sessionId);

  Future<void> _writeHistoryCache(AiHistoryResult result) async {
    if (result.sessionId == null) return;
    await _cache.write(
      LocalCacheContract.aiConversationKey(result.sessionId!),
      {
        'sessionId': result.sessionId,
        'messages': result.messages.map((m) => m.toJson()).toList(),
      },
      LocalCacheContract.profileTtl,
    );
    await _cache.write(LocalCacheContract.aiActiveSessionKey, {
      'sessionId': result.sessionId,
    }, LocalCacheContract.profileTtl);
  }

  AiHistoryResult _historyFromCache(Map<String, dynamic>? cached) {
    if (cached == null) return const AiHistoryResult();
    final messages = (cached['messages'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((j) => AiChatMessage.fromJson(j, fromCache: true))
        .toList();
    return AiHistoryResult(
      sessionId: cached['sessionId'] as String?,
      messages: messages,
      fromCache: true,
    );
  }

  @override
  Future<AiHistoryResult?> readCachedHistory({String? sessionId}) async {
    String? resolvedSessionId = sessionId;
    if (resolvedSessionId == null) {
      final active = await _cache.read(LocalCacheContract.aiActiveSessionKey);
      resolvedSessionId = active?['sessionId'] as String?;
    }
    if (resolvedSessionId == null) return null;
    return _historyFromCache(
      await _cache.read(
        LocalCacheContract.aiConversationKey(resolvedSessionId),
      ),
    );
  }

  @override
  Future<ApiResult<AiHistoryResult>> getHistory({
    String? sessionId,
    bool forceRefresh = false,
  }) async {
    try {
      final data = await getJson(
        _dio,
        AiApiPaths.history,
        queryParameters: sessionId != null ? {'sessionId': sessionId} : null,
      );
      final messages = (data['messages'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(AiChatMessage.fromJson)
          .toList();
      final result = AiHistoryResult(
        sessionId: data['sessionId'] as String?,
        messages: messages,
      );
      await _writeHistoryCache(result);
      return ApiResult.success(result);
    } on AppException catch (e) {
      final cached = await readCachedHistory(sessionId: sessionId);
      if (cached != null) return ApiResult.success(cached);
      return ApiResult.failure(e);
    }
  }

  Future<void> _appendLocalMessages({
    required String? sessionId,
    required AiChatMessage userMessage,
    AiChatMessage? assistantMessage,
  }) async {
    final cached = await readCachedHistory(sessionId: sessionId);
    final existing = cached?.messages ?? [];
    final updated = [
      ...existing,
      userMessage,
      ?assistantMessage,
    ];
    final resolvedSessionId =
        sessionId ?? cached?.sessionId ?? 'local-ai-session';
    await _writeHistoryCache(
      AiHistoryResult(sessionId: resolvedSessionId, messages: updated),
    );
  }

  Future<void> _enqueueMessage(AiSendMessageInput input, String localId) async {
    final sequence = (await _outbox.listAll()).length + 1;
    await _outbox.enqueue(
      OutboxItem(
        idempotencyKey: 'ai-chat-$localId-$sequence',
        kind: OutboxKind.aiChatMessage,
        payload: input.toJson(),
        clientSequence: sequence,
        attemptCount: 0,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  @override
  Future<ApiResult<AiChatResponse>> sendMessage(
    AiSendMessageInput input,
  ) async {
    final localUserId = 'local-user-${DateTime.now().millisecondsSinceEpoch}';
    final userMessage = AiChatMessage(
      id: localUserId,
      role: AiMessageRole.user,
      content: input.message.trim(),
      createdAt: DateTime.now(),
      status: AiMessageStatus.sending,
    );

    try {
      final data = await postJson(_dio, AiApiPaths.chat, input.toJson());
      final response = AiChatResponse.fromJson(data);
      final assistantMessage = AiChatMessage(
        id: response.messageId,
        role: AiMessageRole.assistant,
        content: response.content,
        createdAt: DateTime.now(),
        refused: response.refused,
        humanRedirect: response.humanRedirect,
        escalationRecommended: response.escalationRecommended,
        disclaimer: response.disclaimer,
        escalationDisclosure: response.escalationFields?.disclosure,
        escalationTrigger: response.escalationFields?.trigger,
      );
      await _appendLocalMessages(
        sessionId: response.sessionId,
        userMessage: userMessage.copyWith(status: AiMessageStatus.sent),
        assistantMessage: assistantMessage,
      );
      return ApiResult.success(response);
    } on AppException catch (e) {
      if (isTransientNetworkError(e)) {
        await _enqueueMessage(input, localUserId);
        await _appendLocalMessages(
          sessionId: input.sessionId,
          userMessage: userMessage.copyWith(
            status: AiMessageStatus.pendingSync,
          ),
        );
        return const ApiResult.failure(
          AppException(
            message: 'Saved offline — will sync when online',
            code: offlineQueuedCode,
          ),
        );
      }
      await _appendLocalMessages(
        sessionId: input.sessionId,
        userMessage: userMessage.copyWith(status: AiMessageStatus.failed),
      );
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<TriageResultModel>> runTriage(AiTriageInput input) async {
    try {
      final data = await postJson(_dio, AiApiPaths.triage, input.toJson());
      final symptomsSummary = input.symptoms.join(', ');
      return ApiResult.success(
        TriageResultModel.fromJson(data, symptomsSummary: symptomsSummary),
      );
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<void>> clearHistory({String? sessionId}) async {
    final cached = await readCachedHistory(sessionId: sessionId);
    final resolvedSessionId = sessionId ?? cached?.sessionId;
    if (resolvedSessionId != null) {
      await _cache.write(
        LocalCacheContract.aiConversationKey(resolvedSessionId),
        {'sessionId': resolvedSessionId, 'messages': []},
        LocalCacheContract.profileTtl,
      );
      try {
        await deleteJson(
          _dio,
          '${AiApiPaths.memory}?kind=CONVERSATION&key=$resolvedSessionId',
        );
      } on AppException {
        // Local clear still succeeds offline.
      }
    }
    await _cache.write(
      LocalCacheContract.aiActiveSessionKey,
      {},
      LocalCacheContract.profileTtl,
    );
    await _cache.write(
      LocalCacheContract.aiDraftKey,
      {},
      LocalCacheContract.voiceDraftTtl,
    );
    return const ApiResult.success(null);
  }

  Future<ApiResult<AiChatResponse>> _postMessageOnline(
    AiSendMessageInput input,
  ) async {
    final data = await postJson(_dio, AiApiPaths.chat, input.toJson());
    return ApiResult.success(AiChatResponse.fromJson(data));
  }

  @override
  Future<ApiResult<int>> syncPending() async {
    final items = await _outbox.listReady();
    final pending = items
        .where((i) => i.kind == OutboxKind.aiChatMessage)
        .toList();
    var synced = 0;
    for (final item in pending) {
      try {
        final input = AiSendMessageInput(
          message: item.payload['message'] as String? ?? '',
          sessionId: item.payload['sessionId'] as String?,
          locale: AiLocaleApi.fromApi(item.payload['locale'] as String?),
        );
        final result = await _postMessageOnline(input);
        if (result case ApiSuccess(data: final response)) {
          await _appendLocalMessages(
            sessionId: response.sessionId,
            userMessage: AiChatMessage(
              id: 'synced-user-${item.idempotencyKey}',
              role: AiMessageRole.user,
              content: input.message,
              createdAt: DateTime.now(),
            ),
            assistantMessage: AiChatMessage(
              id: response.messageId,
              role: AiMessageRole.assistant,
              content: response.content,
              createdAt: DateTime.now(),
              refused: response.refused,
              humanRedirect: response.humanRedirect,
              escalationRecommended: response.escalationRecommended,
              disclaimer: response.disclaimer,
              escalationDisclosure: response.escalationFields?.disclosure,
              escalationTrigger: response.escalationFields?.trigger,
            ),
          );
          await _outbox.remove(item.idempotencyKey);
          synced++;
        }
      } on AppException {
        continue;
      }
    }
    return ApiResult.success(synced);
  }

  @override
  Future<ApiResult<void>> escalate({
    String? sessionId,
    String reason = 'DOCTOR_REQUEST',
    String? handoffNote,
  }) async {
    try {
      await postJson(_dio, AiApiPaths.escalate, {
        'sessionId': ?sessionId,
        'reason': reason,
        'handoffNote': ?handoffNote,
      });
      return const ApiResult.success(null);
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }

  @override
  Future<String?> readDraft() async {
    final cached = await _cache.read(LocalCacheContract.aiDraftKey);
    return cached?['text'] as String?;
  }

  @override
  Future<void> saveDraft(String text) async {
    await _cache.write(LocalCacheContract.aiDraftKey, {
      'text': text,
    }, LocalCacheContract.voiceDraftTtl);
  }

  @override
  Future<void> clearDraft() async {
    await _cache.write(
      LocalCacheContract.aiDraftKey,
      {},
      LocalCacheContract.voiceDraftTtl,
    );
  }

  @override
  Future<AiSettings> readSettings() async {
    final cached = await _cache.read(LocalCacheContract.aiSettingsKey);
    if (cached == null) return const AiSettings();
    return AiSettings.fromJson(cached);
  }

  @override
  Future<void> saveSettings(AiSettings settings) async {
    await _cache.write(
      LocalCacheContract.aiSettingsKey,
      settings.toJson(),
      LocalCacheContract.profileTtl,
    );
  }

  @override
  Future<ApiResult<VoiceSttResult>> normalizeVoiceTranscript({
    required String transcript,
    String? sessionId,
    AiLocale locale = AiLocale.bn,
    double confidence = 0.85,
  }) async {
    try {
      final data = await postJson(_dio, VoiceApiPaths.stt, {
        'mode': 'UPLOAD',
        'transcript': transcript,
        'sessionId': ?sessionId,
        'locale': locale.apiValue,
        'confidence': confidence,
      });
      return ApiResult.success(VoiceSttResult.fromJson(data));
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }
}

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepository(
    ref.watch(dioProvider),
    ref.watch(localCacheServiceProvider),
    ref.watch(outboxServiceProvider),
  );
});
