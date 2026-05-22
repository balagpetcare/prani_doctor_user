import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/offline/network_errors.dart';
import '../data/ai_dto.dart';
import '../data/ai_repository.dart';
import '../data/speech_service.dart';

enum AiChatStateKind { idle, loading, success, error, empty, offline }

class AiChatState {
  const AiChatState({
    this.messages = const [],
    this.sessionId,
    this.kind = AiChatStateKind.empty,
    this.fromCache = false,
    this.isSending = false,
    this.errorMessage,
    this.locale = AiLocale.bn,
    this.triageResult,
  });

  final List<AiChatMessage> messages;
  final String? sessionId;
  final AiChatStateKind kind;
  final bool fromCache;
  final bool isSending;
  final String? errorMessage;
  final AiLocale locale;
  final TriageResultModel? triageResult;

  AiChatState copyWith({
    List<AiChatMessage>? messages,
    String? sessionId,
    AiChatStateKind? kind,
    bool? fromCache,
    bool? isSending,
    String? errorMessage,
    AiLocale? locale,
    TriageResultModel? triageResult,
    bool clearTriage = false,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      sessionId: sessionId ?? this.sessionId,
      kind: kind ?? this.kind,
      fromCache: fromCache ?? this.fromCache,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage,
      locale: locale ?? this.locale,
      triageResult: clearTriage ? null : triageResult ?? this.triageResult,
    );
  }
}

final aiLocaleProvider = StateProvider<AiLocale>((ref) => AiLocale.bn);

final speechServiceProvider = Provider<SpeechService>((ref) {
  final service = PlatformSpeechService();
  ref.onDispose(service.dispose);
  return service;
});

final aiChatProvider = AsyncNotifierProvider<AiChatNotifier, AiChatState>(AiChatNotifier.new);

class AiChatNotifier extends AsyncNotifier<AiChatState> {
  @override
  Future<AiChatState> build() async {
    ref.watch(aiLocaleProvider);
    return _loadHistory();
  }

  Future<AiChatState> _loadHistory() async {
    final result = await ref.read(aiRepositoryProvider).getHistory();
    return result.when(
      success: (history) {
        if (history.messages.isEmpty) {
          return AiChatState(
            sessionId: history.sessionId,
            kind: AiChatStateKind.empty,
            fromCache: history.fromCache,
            locale: ref.read(aiLocaleProvider),
          );
        }
        return AiChatState(
          messages: history.messages,
          sessionId: history.sessionId,
          kind: history.fromCache ? AiChatStateKind.offline : AiChatStateKind.success,
          fromCache: history.fromCache,
          locale: ref.read(aiLocaleProvider),
        );
      },
      failure: (e) => AiChatState(
        kind: AiChatStateKind.error,
        errorMessage: e.message,
        locale: ref.read(aiLocaleProvider),
      ),
    );
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = AsyncData(await _loadHistory());
  }

  Future<void> sendMessage(String text) async {
    final current = state.value ?? const AiChatState();
    state = AsyncData(current.copyWith(isSending: true, kind: AiChatStateKind.loading));

    final result = await ref.read(aiRepositoryProvider).sendMessage(
          AiSendMessageInput(
            message: text,
            sessionId: current.sessionId,
            locale: ref.read(aiLocaleProvider),
          ),
        );

    result.when(
      success: (response) async {
        final refreshed = await ref.read(aiRepositoryProvider).getHistory(sessionId: response.sessionId);
        refreshed.when(
          success: (history) {
            state = AsyncData(
              current.copyWith(
                messages: history.messages,
                sessionId: history.sessionId,
                kind: AiChatStateKind.success,
                isSending: false,
                fromCache: history.fromCache,
              ),
            );
          },
          failure: (_) {
            state = AsyncData(
              current.copyWith(
                isSending: false,
                kind: AiChatStateKind.success,
                sessionId: response.sessionId,
              ),
            );
          },
        );
      },
      failure: (e) async {
        if (e.code == offlineQueuedCode) {
          final cached = await ref.read(aiRepositoryProvider).readCachedHistory(sessionId: current.sessionId);
          state = AsyncData(
            (cached != null
                    ? current.copyWith(messages: cached.messages, sessionId: cached.sessionId)
                    : current)
                .copyWith(
              kind: AiChatStateKind.offline,
              isSending: false,
            ),
          );
          return;
        }
        state = AsyncData(
          current.copyWith(
            kind: AiChatStateKind.error,
            errorMessage: e.message,
            isSending: false,
          ),
        );
      },
    );
  }

  Future<void> retryMessage(String content) => sendMessage(content);

  Future<void> clearHistory() async {
    await ref.read(aiRepositoryProvider).clearHistory(sessionId: state.value?.sessionId);
    state = AsyncData(
      AiChatState(
        kind: AiChatStateKind.empty,
        locale: ref.read(aiLocaleProvider),
      ),
    );
  }

  Future<void> runTriage(List<String> symptoms) async {
    final current = state.value ?? const AiChatState();
    state = AsyncData(current.copyWith(isSending: true, kind: AiChatStateKind.loading));
    final result = await ref.read(aiRepositoryProvider).runTriage(
          AiTriageInput(
            symptoms: symptoms,
            sessionId: current.sessionId,
            locale: ref.read(aiLocaleProvider),
          ),
        );
    result.when(
      success: (triage) {
        state = AsyncData(
          current.copyWith(
            triageResult: triage,
            isSending: false,
            kind: current.messages.isEmpty ? AiChatStateKind.empty : AiChatStateKind.success,
          ),
        );
      },
      failure: (e) {
        state = AsyncData(
          current.copyWith(
            isSending: false,
            kind: AiChatStateKind.error,
            errorMessage: e.message,
          ),
        );
      },
    );
  }
}

final aiDraftInputProvider = StateProvider<String>((ref) => '');
