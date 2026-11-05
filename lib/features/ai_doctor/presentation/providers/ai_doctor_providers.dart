import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ai/presentation/ai_providers.dart';
import '../../data/ai_doctor_dto.dart';
import '../../data/ai_doctor_repository.dart';

class AiDoctorCaseViewState {
  const AiDoctorCaseViewState({
    this.aiCase,
    this.isLoading = false,
    this.errorMessage,
    this.lastAnalysis,
  });

  final AiDoctorCaseModel? aiCase;
  final bool isLoading;
  final String? errorMessage;
  final AnalyzeCaseResultModel? lastAnalysis;

  AiDoctorCaseViewState copyWith({
    AiDoctorCaseModel? aiCase,
    bool? isLoading,
    String? errorMessage,
    AnalyzeCaseResultModel? lastAnalysis,
    bool clearAnalysis = false,
  }) {
    return AiDoctorCaseViewState(
      aiCase: aiCase ?? this.aiCase,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      lastAnalysis: clearAnalysis ? null : lastAnalysis ?? this.lastAnalysis,
    );
  }
}

final aiDoctorHistoryProvider =
    FutureProvider<List<AiDoctorCaseModel>>((ref) async {
  return ref.read(aiDoctorRepositoryProvider).readCaseHistory();
});

final aiDoctorActiveCaseIdProvider = FutureProvider<String?>((ref) async {
  return ref.read(aiDoctorRepositoryProvider).readActiveCaseId();
});

final aiDoctorCaseProvider = AsyncNotifierProvider.family<
    AiDoctorCaseNotifier, AiDoctorCaseViewState, String>(
  AiDoctorCaseNotifier.new,
);

class AiDoctorCaseNotifier
    extends FamilyAsyncNotifier<AiDoctorCaseViewState, String> {
  @override
  Future<AiDoctorCaseViewState> build(String caseId) async {
    final result = await ref.read(aiDoctorRepositoryProvider).getCase(caseId);
    return result.when(
      success: (aiCase) => AiDoctorCaseViewState(aiCase: aiCase),
      failure: (e) => AiDoctorCaseViewState(errorMessage: e.message),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await build(arg));
  }

  Future<AnalyzeCaseResultModel?> submitIntake(SubmitIntakeInput input) async {
    final current = state.value ?? const AiDoctorCaseViewState();
    state = AsyncData(current.copyWith(isLoading: true, errorMessage: null));

    final result = await ref
        .read(aiDoctorRepositoryProvider)
        .submitIntake(arg, input);

    return result.when(
      success: (analysis) async {
        await _appendAnalysisMessage(analysis);
        state = AsyncData(
          current.copyWith(
            aiCase: analysis.aiCase,
            lastAnalysis: analysis,
            isLoading: false,
          ),
        );
        return analysis;
      },
      failure: (e) {
        state = AsyncData(
          current.copyWith(isLoading: false, errorMessage: e.message),
        );
        return null;
      },
    );
  }

  Future<AnalyzeCaseResultModel?> analyze() async {
    final current = state.value ?? const AiDoctorCaseViewState();
    state = AsyncData(current.copyWith(isLoading: true, errorMessage: null));

    final result = await ref.read(aiDoctorRepositoryProvider).analyze(arg);

    return result.when(
      success: (analysis) async {
        await _appendAnalysisMessage(analysis);
        state = AsyncData(
          current.copyWith(
            aiCase: analysis.aiCase,
            lastAnalysis: analysis,
            isLoading: false,
          ),
        );
        return analysis;
      },
      failure: (e) {
        state = AsyncData(
          current.copyWith(isLoading: false, errorMessage: e.message),
        );
        return null;
      },
    );
  }

  Future<EscalateCaseResultModel?> escalate() async {
    final current = state.value ?? const AiDoctorCaseViewState();
    state = AsyncData(current.copyWith(isLoading: true, errorMessage: null));

    final result = await ref.read(aiDoctorRepositoryProvider).escalate(arg);

    return result.when(
      success: (escalation) {
        state = AsyncData(
          current.copyWith(aiCase: escalation.aiCase, isLoading: false),
        );
        return escalation;
      },
      failure: (e) {
        state = AsyncData(
          current.copyWith(isLoading: false, errorMessage: e.message),
        );
        return null;
      },
    );
  }

  Future<void> _appendAnalysisMessage(AnalyzeCaseResultModel analysis) async {
    final repo = ref.read(aiDoctorRepositoryProvider);
    final existing = await repo.readChatMessages(arg);
    final message = AiDoctorChatMessage.fromAnalysis(analysis);
    await repo.writeChatMessages(arg, [...existing, message]);
    ref.invalidate(aiDoctorChatProvider(arg));
  }
}

class AiDoctorChatState {
  const AiDoctorChatState({
    this.messages = const [],
    this.isSending = false,
    this.errorMessage,
    this.sessionId,
  });

  final List<AiDoctorChatMessage> messages;
  final bool isSending;
  final String? errorMessage;
  final String? sessionId;

  AiDoctorChatState copyWith({
    List<AiDoctorChatMessage>? messages,
    bool? isSending,
    String? errorMessage,
    String? sessionId,
  }) {
    return AiDoctorChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}

final aiDoctorChatProvider = AsyncNotifierProvider.family<
    AiDoctorChatNotifier, AiDoctorChatState, String>(
  AiDoctorChatNotifier.new,
);

class AiDoctorChatNotifier
    extends FamilyAsyncNotifier<AiDoctorChatState, String> {
  @override
  Future<AiDoctorChatState> build(String caseId) async {
    final messages =
        await ref.read(aiDoctorRepositoryProvider).readChatMessages(caseId);
    final caseState = ref.read(aiDoctorCaseProvider(caseId)).valueOrNull;
    return AiDoctorChatState(
      messages: messages,
      sessionId: caseState?.aiCase?.sessionId,
    );
  }

  Future<bool> sendMessage(String text) async {
    if (text.trim().isEmpty) return false;

    final current = state.value ?? const AiDoctorChatState();
    final userMessage = AiDoctorChatMessage(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      role: AiDoctorMessageRole.user,
      content: text.trim(),
      createdAt: DateTime.now(),
      isSending: true,
    );
    final pending = [...current.messages, userMessage];
    state = AsyncData(current.copyWith(messages: pending, isSending: true));

    final caseState = ref.read(aiDoctorCaseProvider(arg)).valueOrNull;
    final aiCase = caseState?.aiCase;
    if (aiCase == null) {
      state = AsyncData(
        current.copyWith(
          isSending: false,
          errorMessage: 'Case not loaded',
        ),
      );
      return false;
    }

    final locale = ref.read(aiLocaleProvider);
    final result = await ref.read(aiDoctorRepositoryProvider).askAssistant(
          AiDoctorAssistantInput(
            message: text,
            caseId: arg,
            sessionId: current.sessionId ?? aiCase.sessionId,
            livestockId: aiCase.livestockId,
            locale: locale,
          ),
        );

    return result.when(
      success: (response) async {
        final assistant = AiDoctorChatMessage.fromAssistant(response);
        final updated = [
          ...pending.map(
            (m) => m.id == userMessage.id
                ? m.copyWith(isSending: false)
                : m,
          ),
          assistant,
        ];
        await ref.read(aiDoctorRepositoryProvider).writeChatMessages(arg, updated);
        state = AsyncData(
          current.copyWith(
            messages: updated,
            isSending: false,
            sessionId: response.sessionId,
          ),
        );
        return true;
      },
      failure: (e) {
        state = AsyncData(
          current.copyWith(
            messages: pending,
            isSending: false,
            errorMessage: e.message,
          ),
        );
        return false;
      },
    );
  }
}

Future<AiDoctorCaseModel?> createAiDoctorCase(
  WidgetRef ref, {
  required String species,
  String? livestockId,
  String? symptomCheckSessionId,
}) async {
  final locale = ref.read(aiLocaleProvider);
  final result = await ref.read(aiDoctorRepositoryProvider).createCase(
        CreateAiDoctorCaseInput(
          species: species,
          livestockId: livestockId,
          locale: locale,
          symptomCheckSessionId: symptomCheckSessionId,
        ),
      );
  return result.when(
    success: (aiCase) => aiCase,
    failure: (_) => null,
  );
}

String routeForCaseState(AiDoctorCaseModel aiCase) {
  if (aiCase.isEmergency ||
      aiCase.state == AiDoctorCaseStateEnum.emergencyTriage) {
    return 'emergency';
  }
  switch (aiCase.state) {
    case AiDoctorCaseStateEnum.created:
    case AiDoctorCaseStateEnum.intake:
      return 'intake';
    case AiDoctorCaseStateEnum.awaitingClarification:
      return 'chat';
    case AiDoctorCaseStateEnum.responseDelivered:
    case AiDoctorCaseStateEnum.analyzing:
      return 'chat';
    case AiDoctorCaseStateEnum.escalated:
      return 'escalate';
    case AiDoctorCaseStateEnum.blocked:
    case AiDoctorCaseStateEnum.closed:
      return 'result';
    default:
      return 'intake';
  }
}
