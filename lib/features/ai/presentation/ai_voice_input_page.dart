import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import '../data/ai_repository.dart';
import 'ai_providers.dart';
import 'widgets/ai_feedback.dart';

class AiVoiceInputPage extends ConsumerStatefulWidget {
  const AiVoiceInputPage({super.key});

  @override
  ConsumerState<AiVoiceInputPage> createState() => _AiVoiceInputPageState();
}

class _AiVoiceInputPageState extends ConsumerState<AiVoiceInputPage> {
  String? _transcript;
  String? _error;
  bool _initializing = true;
  bool _permissionDenied = false;
  bool _normalizing = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final locale = ref.read(aiLocaleProvider);
    final service = ref.read(speechServiceProvider);
    final ok = await service.initialize(locale: locale);
    if (!mounted) return;
    setState(() {
      _initializing = false;
      _permissionDenied = !ok;
    });
  }

  Future<void> _startListening() async {
    setState(() {
      _error = null;
      _transcript = null;
    });
    final service = ref.read(speechServiceProvider);
    final started = await service.startListening();
    if (!started && mounted) {
      setState(() => _error = service.lastError ?? 'Could not start listening');
    }
  }

  Future<void> _stopListening() async {
    final l10n = AppLocalizations.of(context)!;
    final service = ref.read(speechServiceProvider);
    final raw = await service.stopListening();
    if (!mounted) return;
    if (raw == null || raw.isEmpty) {
      setState(() => _error = l10n.aiEmptyTranscript);
      return;
    }
    setState(() {
      _normalizing = true;
      _transcript = raw;
    });
    final chatState = ref.read(aiChatProvider).value;
    final result = await ref
        .read(aiRepositoryProvider)
        .normalizeVoiceTranscript(
          transcript: raw,
          sessionId: chatState?.sessionId,
          locale: ref.read(aiLocaleProvider),
        );
    if (!mounted) return;
    result.when(
      success: (stt) {
        setState(() {
          _normalizing = false;
          _transcript = stt.normalizedText.isNotEmpty
              ? stt.normalizedText
              : raw;
        });
        ref.read(aiDraftInputProvider.notifier).state = _transcript!;
      },
      failure: (e) {
        setState(() {
          _normalizing = false;
          _transcript = raw;
          _error = e.message;
        });
        ref.read(aiDraftInputProvider.notifier).state = raw;
      },
    );
  }

  Future<void> _cancel() async {
    await ref.read(speechServiceProvider).cancel();
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final speech = ref.watch(speechServiceProvider);
    final isListening = speech.isListeningListenable.value;
    final partial = speech.partialTranscriptListenable.value;

    if (_initializing) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.aiVoiceTitle)),
        body: AiFeedback.loading(),
      );
    }
    if (_permissionDenied) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.aiVoiceTitle)),
        body: AiFeedback.permissionDenied(context),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aiVoiceTitle),
        leading: IconButton(onPressed: _cancel, icon: const Icon(Icons.close)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.aiVoiceInstructions,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (isListening)
              LinearProgressIndicator(value: partial.isEmpty ? null : 1),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Text(
                  _transcript ?? partial.ifEmpty ?? l10n.aiVoiceTapHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            if (_error != null) ...[
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 8),
            ],
            if (_normalizing) const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _normalizing
                  ? null
                  : isListening
                  ? _stopListening
                  : _startListening,
              icon: Icon(isListening ? Icons.stop : Icons.mic),
              label: Text(isListening ? l10n.aiVoiceStop : l10n.aiVoiceStart),
            ),
            const SizedBox(height: 8),
            if (_transcript != null && !_normalizing)
              FilledButton.tonal(
                onPressed: () =>
                    context.go(AppRoutes.aiChat, extra: _transcript),
                child: Text(l10n.aiVoiceUseText),
              ),
          ],
        ),
      ),
    );
  }
}

extension on String {
  String? get ifEmpty => isEmpty ? null : this;
}
