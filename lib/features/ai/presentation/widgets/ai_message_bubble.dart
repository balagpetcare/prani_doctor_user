import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../data/ai_dto.dart';
import '../../data/ai_escalation_disclosure_dto.dart';
import 'ai_escalation_disclosure_strip.dart';

class AiMessageBubble extends ConsumerWidget {
  const AiMessageBubble({super.key, required this.message, this.onRetry});

  final AiChatMessage message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isUser = message.role == AiMessageRole.user;
    final isSystem = message.role == AiMessageRole.system;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = isSystem
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : isUser
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.secondaryContainer;

    final trigger = message.escalationTrigger ??
        escalationTriggerFromChat(
          refused: message.refused,
          escalationRecommended: message.escalationRecommended,
          humanRedirect: message.humanRedirect,
        );

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.92,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: message.content));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.aiCopied)),
                );
              },
              child: Card(
                color: color,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(message.content),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(message.createdAt),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      if (message.disclaimer != null &&
                          message.disclaimer!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            message.disclaimer!,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(fontStyle: FontStyle.italic),
                          ),
                        ),
                      if (message.isFailed && onRetry != null)
                        TextButton(
                          onPressed: onRetry,
                          child: Text(l10n.aiRetry),
                        ),
                      if (message.status == AiMessageStatus.pendingSync)
                        Text(
                          l10n.aiPendingSync,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (!isUser && trigger != null)
              AiEscalationDisclosureStrip(
                trigger: trigger,
                apiDisclosure: message.escalationDisclosure,
                showKeywordLimitation:
                    trigger == AiEscalationDisclosureTrigger.emergency ||
                    trigger == AiEscalationDisclosureTrigger.high,
                onRequestHumanReview: () => requestAiHumanReview(ref),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
