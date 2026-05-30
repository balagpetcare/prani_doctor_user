import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../data/ai_disclaimer_dto.dart';
import '../../data/ai_dto.dart';
import '../ai_providers.dart';
import '../../data/ai_compliance_dto.dart';
import '../compliance/ai_compliance_model.dart';
import '../compliance/ai_output_compliance_wrapper.dart';
import '../widgets/ai_escalation_disclosure_strip.dart';

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

    if (isUser) {
      return Align(
        alignment: alignment,
        child: _MessageCard(
          color: color,
          message: message,
          l10n: l10n,
          onRetry: onRetry,
        ),
      );
    }

    final evaluation = AiComplianceEvaluation.fromChatMessage(message);

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.92,
        ),
        child: AiOutputComplianceWrapper(
          evaluation: evaluation,
          inlineDisclaimer: message.disclaimer,
          apiEscalationDisclosure: message.escalationDisclosure,
          showKeywordLimitation:
              evaluation.emergency || evaluation.riskLevel == AiComplianceRiskLevel.high,
          onRequestHumanReview: () => requestAiHumanReview(ref),
          child: _MessageCard(
            color: color,
            message: message,
            l10n: l10n,
            onRetry: onRetry,
            showInlineDisclaimer: false,
          ),
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.color,
    required this.message,
    required this.l10n,
    this.onRetry,
    this.showInlineDisclaimer = true,
  });

  final Color color;
  final AiChatMessage message;
  final AppLocalizations l10n;
  final VoidCallback? onRetry;
  final bool showInlineDisclaimer;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
              if (showInlineDisclaimer &&
                  message.disclaimer != null &&
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
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
