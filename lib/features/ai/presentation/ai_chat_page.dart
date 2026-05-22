import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import '../data/ai_dto.dart';
import '../data/ai_validation.dart';
import 'ai_providers.dart';
import 'widgets/ai_disclaimer_banner.dart';
import 'widgets/ai_feedback.dart';
import 'widgets/ai_message_bubble.dart';
import 'widgets/triage_card.dart';

class AiChatPage extends ConsumerStatefulWidget {
  const AiChatPage({super.key, this.initialPrompt});

  final String? initialPrompt;

  @override
  ConsumerState<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends ConsumerState<AiChatPage> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _symptomController = TextEditingController();
  bool _showTriage = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      _inputController.text = widget.initialPrompt!;
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _symptomController.dispose();
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
    final l10n = AppLocalizations.of(context)!;
    final text = _inputController.text;
    final error = AiValidation.validateMessage(
      text,
      emptyMessage: l10n.aiMessageRequired,
      tooLong: l10n.aiMessageTooLong,
    );
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    _inputController.clear();
    await ref.read(aiChatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  Future<void> _runTriage() async {
    final l10n = AppLocalizations.of(context)!;
    final symptoms = _symptomController.text
        .split(RegExp(r'[,;\n]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final error = AiValidation.validateSymptoms(symptoms, emptyMessage: l10n.aiSymptomsRequired);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    await ref.read(aiChatProvider.notifier).runTriage(symptoms);
    setState(() => _showTriage = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chatAsync = ref.watch(aiChatProvider);
    final locale = ref.watch(aiLocaleProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aiAskTitle),
        actions: [
          PopupMenuButton<AiLocale>(
            initialValue: locale,
            onSelected: (value) => ref.read(aiLocaleProvider.notifier).state = value,
            itemBuilder: (context) => [
              PopupMenuItem(value: AiLocale.bn, child: Text(l10n.aiLocaleBn)),
              PopupMenuItem(value: AiLocale.en, child: Text(l10n.aiLocaleEn)),
            ],
            icon: const Icon(Icons.translate),
          ),
          IconButton(
            onPressed: () => context.push(AppRoutes.aiVoiceInput),
            icon: const Icon(Icons.mic_none),
          ),
          IconButton(
            onPressed: () => ref.read(aiChatProvider.notifier).clearHistory(),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: chatAsync.when(
        loading: () => AiFeedback.skeleton(),
        error: (e, _) => AiFeedback.error(context, message: e.toString(), onRetry: () => ref.read(aiChatProvider.notifier).reload()),
        data: (state) {
          return Column(
            children: [
              const AiDisclaimerBanner(),
              if (state.fromCache || state.kind == AiChatStateKind.offline)
                AiFeedback.offlineHint(context),
              Expanded(
                child: state.messages.isEmpty
                    ? AiFeedback.empty(context)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) {
                          final message = state.messages[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: AiMessageBubble(
                              message: message,
                              onRetry: message.isFailed ? () => ref.read(aiChatProvider.notifier).retryMessage(message.content) : null,
                            ),
                          );
                        },
                      ),
              ),
              if (state.triageResult != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TriageCard(result: state.triageResult!),
                ),
              if (_showTriage)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _symptomController,
                        decoration: InputDecoration(
                          labelText: l10n.aiSymptomsLabel,
                          hintText: l10n.aiSymptomsHint,
                        ),
                        minLines: 2,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 8),
                      FilledButton(onPressed: state.isSending ? null : _runTriage, child: Text(l10n.aiRunTriage)),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: AiSuggestionChips(
                  onSelected: (text) {
                    _inputController.text = text;
                    if (text == l10n.aiSuggestionSymptoms) {
                      setState(() => _showTriage = true);
                    }
                  },
                ),
              ),
              if (state.isSending) const LinearProgressIndicator(minHeight: 2),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(hintText: l10n.aiInputHint),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: state.isSending ? null : _send,
                        child: Text(l10n.aiSend),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
