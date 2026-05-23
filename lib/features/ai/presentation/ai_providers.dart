import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ai_dto.dart';
import '../data/ai_repository.dart';
import '../data/speech_service.dart';
import '../../../core/offline/network_errors.dart';

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

final aiLocaleProvider = Provider<AiLocale>((ref) {
  return ref
      .watch(aiSettingsProvider)
      .maybeWhen(data: (s) => s.locale, orElse: () => AiLocale.bn);
});

final speechServiceProvider = Provider<SpeechService>((ref) {
  final service = PlatformSpeechService();
  ref.onDispose(service.dispose);
  return service;
});

class AiSettingsNotifier extends AsyncNotifier<AiSettings> {
  @override
  Future<AiSettings> build() async {
    return ref.read(aiRepositoryProvider).readSettings();
  }

  Future<void> save(AiSettings settings) async {
    await ref.read(aiRepositoryProvider).saveSettings(settings);
    state = AsyncData(settings);
  }
}

final aiSettingsProvider =
    AsyncNotifierProvider<AiSettingsNotifier, AiSettings>(
      AiSettingsNotifier.new,
    );

final aiSubmissionProvider = StateProvider<bool>((ref) => false);

final aiChatProvider = AsyncNotifierProvider<AiChatNotifier, AiChatState>(
  AiChatNotifier.new,
);

class AiChatNotifier extends AsyncNotifier<AiChatState> {
  @override
  Future<AiChatState> build() async {
    final settings = await ref.read(aiRepositoryProvider).readSettings();
    final cached = await ref.read(aiRepositoryProvider).readCachedHistory();
    if (cached != null && cached.messages.isNotEmpty) {
      unawaited(reload(silent: true));
      return _stateFromHistory(cached, settings.locale);
    }
    return _loadHistory(settings.locale);
  }

  AiChatState _stateFromHistory(AiHistoryResult history, AiLocale locale) {
    if (history.messages.isEmpty) {
      return AiChatState(
        sessionId: history.sessionId,
        kind: AiChatStateKind.empty,
        locale: locale,
      );
    }
    return AiChatState(
      messages: history.messages,
      sessionId: history.sessionId,
      kind: history.fromCache
          ? AiChatStateKind.offline
          : AiChatStateKind.success,
      fromCache: history.fromCache,
      locale: locale,
    );
  }

  Future<AiChatState> _loadHistory(AiLocale locale) async {
    final result = await ref.read(aiRepositoryProvider).getHistory();
    return result.when(
      success: (history) => _stateFromHistory(history, locale),
      failure: (e) => AiChatState(
        kind: AiChatStateKind.error,
        errorMessage: e.message,
        locale: locale,
      ),
    );
  }

  Future<void> reload({bool silent = false}) async {
    if (!silent) state = const AsyncLoading();
    final locale = ref.read(aiLocaleProvider);
    try {
      state = AsyncData(await _loadHistory(locale));
    } catch (e, st) {
      if (!silent) state = AsyncError(e, st);
    }
  }

  Future<void> sendMessage(String text) async {
    if (ref.read(aiSubmissionProvider)) return;
    ref.read(aiSubmissionProvider.notifier).state = true;

    final current =
        state.value ?? AiChatState(locale: ref.read(aiLocaleProvider));
    state = AsyncData(
      current.copyWith(isSending: true, kind: AiChatStateKind.loading),
    );
    await ref.read(aiRepositoryProvider).clearDraft();

    final result = await ref
        .read(aiRepositoryProvider)
        .sendMessage(
          AiSendMessageInput(
            message: text,
            sessionId: current.sessionId,
            locale: ref.read(aiLocaleProvider),
          ),
        );

    ref.read(aiSubmissionProvider.notifier).state = false;

    await result.when(
      success: (response) async {
        final refreshed = await ref
            .read(aiRepositoryProvider)
            .getHistory(sessionId: response.sessionId);
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
          final cached = await ref
              .read(aiRepositoryProvider)
              .readCachedHistory(sessionId: current.sessionId);
          state = AsyncData(
            (cached != null
                    ? current.copyWith(
                        messages: cached.messages,
                        sessionId: cached.sessionId,
                      )
                    : current)
                .copyWith(kind: AiChatStateKind.offline, isSending: false),
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

  Future<void> regenerateLast() async {
    final messages = state.value?.messages ?? const [];
    for (var i = messages.length - 1; i >= 0; i--) {
      if (messages[i].role == AiMessageRole.user &&
          messages[i].content.trim().isNotEmpty) {
        await sendMessage(messages[i].content);
        return;
      }
    }
  }

  Future<void> clearHistory() async {
    await ref
        .read(aiRepositoryProvider)
        .clearHistory(sessionId: state.value?.sessionId);
    state = AsyncData(
      AiChatState(
        kind: AiChatStateKind.empty,
        locale: ref.read(aiLocaleProvider),
      ),
    );
  }

  Future<void> runTriage(List<String> symptoms) async {
    if (ref.read(aiSubmissionProvider)) return;
    ref.read(aiSubmissionProvider.notifier).state = true;
    final current =
        state.value ?? AiChatState(locale: ref.read(aiLocaleProvider));
    state = AsyncData(
      current.copyWith(isSending: true, kind: AiChatStateKind.loading),
    );
    final result = await ref
        .read(aiRepositoryProvider)
        .runTriage(
          AiTriageInput(
            symptoms: symptoms,
            sessionId: current.sessionId,
            locale: ref.read(aiLocaleProvider),
          ),
        );
    ref.read(aiSubmissionProvider.notifier).state = false;
    result.when(
      success: (triage) {
        state = AsyncData(
          current.copyWith(
            triageResult: triage,
            isSending: false,
            kind: current.messages.isEmpty
                ? AiChatStateKind.empty
                : AiChatStateKind.success,
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

  Future<bool> escalateToHuman({
    String reason = 'DOCTOR_REQUEST',
    String? note,
  }) async {
    final sessionId = state.value?.sessionId;
    final result = await ref
        .read(aiRepositoryProvider)
        .escalate(sessionId: sessionId, reason: reason, handoffNote: note);
    return result.when(success: (_) => true, failure: (_) => false);
  }
}

final aiDraftInputProvider = StateProvider<String>((ref) => '');

Future<void> persistAiDraft(WidgetRef ref, String text) async {
  ref.read(aiDraftInputProvider.notifier).state = text;
  if (text.trim().isEmpty) {
    await ref.read(aiRepositoryProvider).clearDraft();
  } else {
    await ref.read(aiRepositoryProvider).saveDraft(text);
  }
}

Future<String?> loadAiDraft(WidgetRef ref) async {
  final cached = await ref.read(aiRepositoryProvider).readDraft();
  if (cached != null && cached.isNotEmpty) {
    ref.read(aiDraftInputProvider.notifier).state = cached;
  }
  return cached;
}
