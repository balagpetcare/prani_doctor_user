import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import 'ai_providers.dart';
import 'compliance/ai_compliance_model.dart';
import 'compliance/ai_compliance_shell.dart';
import 'widgets/ai_feedback.dart';
import 'widgets/ai_message_bubble.dart';

class AiHistoryPage extends ConsumerWidget {
  const AiHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final chatAsync = ref.watch(aiChatProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aiHistoryTitle),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.aiChat),
            icon: const Icon(Icons.chat_outlined),
          ),
        ],
      ),
      body: AiCompliancePageBody(
        surface: AiComplianceSurface.chat,
        showEscalationAwarenessBanner: true,
        child: chatAsync.when(
          loading: AiFeedback.loading,
          error: (e, _) => AiFeedback.error(
            context,
            message: e.toString(),
            onRetry: () => ref.read(aiChatProvider.notifier).reload(),
          ),
          data: (state) {
            if (state.messages.isEmpty) {
              return AiFeedback.empty(context);
            }
            return RefreshIndicator(
              onRefresh: () => ref.read(aiChatProvider.notifier).reload(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.messages.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (state.fromCache) AiFeedback.offlineHint(context),
                        if (state.sessionId != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              '${l10n.aiSessionLabel}: ${state.sessionId}',
                            ),
                          ),
                      ],
                    );
                  }
                  final message = state.messages[index - 1];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AiMessageBubble(message: message),
                  );
                },
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: chatAsync.maybeWhen(
        data: (state) => state.messages.isNotEmpty
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: OutlinedButton(
                    onPressed: () async {
                      await ref.read(aiChatProvider.notifier).clearHistory();
                      if (context.mounted) context.push(AppRoutes.aiChat);
                    },
                    child: Text(l10n.aiClearHistory),
                  ),
                ),
              )
            : null,
        orElse: () => null,
      ),
    );
  }
}
