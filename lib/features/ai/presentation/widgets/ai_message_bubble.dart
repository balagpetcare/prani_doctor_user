import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../data/ai_dto.dart';

class AiMessageBubble extends StatelessWidget {
  const AiMessageBubble({super.key, required this.message, this.onRetry});

  final AiChatMessage message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isUser = message.role == AiMessageRole.user;
    final isSystem = message.role == AiMessageRole.system;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = isSystem
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : isUser
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.secondaryContainer;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        child: GestureDetector(
          onLongPress: () {
            Clipboard.setData(ClipboardData(text: message.content));
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(l10n.aiCopied)));
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
                  if (message.isFailed && onRetry != null)
                    TextButton(onPressed: onRetry, child: Text(l10n.aiRetry)),
                  if (message.status == AiMessageStatus.pendingSync)
                    Text(
                      l10n.aiPendingSync,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  if (message.escalationRecommended)
                    Text(
                      l10n.aiEscalationHint,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
