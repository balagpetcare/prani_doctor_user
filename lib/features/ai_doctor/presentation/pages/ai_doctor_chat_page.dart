import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/app_routes.dart';
import '../../../ai/presentation/compliance/ai_compliance_model.dart';
import '../../../ai/presentation/compliance/ai_compliance_shell.dart';
import '../../data/ai_doctor_dto.dart';
import '../providers/ai_doctor_providers.dart';
import '../widgets/analysis_message_card.dart';
import '../widgets/risk_banner.dart';

class AiDoctorChatPage extends ConsumerStatefulWidget {
  const AiDoctorChatPage({super.key, required this.caseId});

  final String caseId;

  @override
  ConsumerState<AiDoctorChatPage> createState() => _AiDoctorChatPageState();
}

class _AiDoctorChatPageState extends ConsumerState<AiDoctorChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    final ok = await ref
        .read(aiDoctorChatProvider(widget.caseId).notifier)
        .sendMessage(text);
    if (!ok && mounted) {
      final err = ref.read(aiDoctorChatProvider(widget.caseId)).valueOrNull?.errorMessage;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      }
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final caseAsync = ref.watch(aiDoctorCaseProvider(widget.caseId));
    final chatAsync = ref.watch(aiDoctorChatProvider(widget.caseId));
    final lastAnalysis = caseAsync.valueOrNull?.lastAnalysis;

    ref.listen(aiDoctorChatProvider(widget.caseId), (_, next) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Doctor চ্যাট'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'ফলাফল',
            onPressed: () =>
                context.push(AppRoutes.aiDoctorCaseResult(widget.caseId)),
          ),
          IconButton(
            icon: const Icon(Icons.support_agent),
            tooltip: 'ভেটে হস্তান্তর',
            onPressed: () =>
                context.push(AppRoutes.aiDoctorCaseHandoff(widget.caseId)),
          ),
        ],
      ),
      body: AiCompliancePageBody(
        surface: AiComplianceSurface.symptomCheck,
        showEscalationAwarenessBanner: true,
        child: Column(
          children: [
            caseAsync.when(
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (_, _) => const SizedBox.shrink(),
              data: (viewState) {
                final risk = viewState.aiCase?.riskAssessment ??
                    lastAnalysis?.riskAssessment;
                if (risk == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: RiskBanner(risk: risk),
                );
              },
            ),
            if (lastAnalysis?.clarificationQuestions.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.all(12),
                child: ClarificationPanel(
                  questions: lastAnalysis!.clarificationQuestions,
                  onAnswer: (_) =>
                      context.push(AppRoutes.aiDoctorCaseIntake(widget.caseId)),
                ),
              ),
            Expanded(
              child: chatAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (chatState) {
                  if (chatState.messages.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'লক্ষণ জমা দিলে বিশ্লেষণ এখানে দেখাবে। '
                          'পরে প্রশ্ন জিজ্ঞেস করতে পারেন।',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, index) {
                      final message = chatState.messages[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: message.role == AiDoctorMessageRole.user
                            ? AiDoctorUserBubble(message: message)
                            : AnalysisMessageCard(
                                message: message,
                                onEscalate: () => context.push(
                                  AppRoutes.aiDoctorCaseHandoff(widget.caseId),
                                ),
                              ),
                      );
                    },
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'আরও প্রশ্ন করুন…',
                          border: OutlineInputBorder(),
                        ),
                        minLines: 1,
                        maxLines: 4,
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: chatAsync.valueOrNull?.isSending == true
                          ? null
                          : _send,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
