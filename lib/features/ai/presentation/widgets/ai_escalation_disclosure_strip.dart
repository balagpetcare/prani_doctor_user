import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../../routing/app_routes.dart';
import '../../data/ai_escalation_disclosure_dto.dart';
import '../ai_escalation_disclosure_providers.dart';
import '../ai_providers.dart';

class AiEscalationDisclosureStrip extends ConsumerWidget {
  const AiEscalationDisclosureStrip({
    super.key,
    required this.trigger,
    this.apiDisclosure,
    this.showKeywordLimitation = false,
    this.showSupportAction = true,
    this.showFindVetAction = true,
    this.onRequestHumanReview,
  });

  final AiEscalationDisclosureTrigger trigger;
  final String? apiDisclosure;
  final bool showKeywordLimitation;
  final bool showSupportAction;
  final bool showFindVetAction;
  final VoidCallback? onRequestHumanReview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final text = resolveEscalationDisclosureText(
      ref,
      trigger: trigger,
      apiDisclosure: apiDisclosure,
    );
    if (text == null || text.isEmpty) return const SizedBox.shrink();

    final isEmergency = trigger == AiEscalationDisclosureTrigger.emergency;
    final color = isEmergency ? theme.colorScheme.errorContainer : theme.colorScheme.tertiaryContainer;
    final iconColor = isEmergency ? theme.colorScheme.error : theme.colorScheme.tertiary;

    final keywordNote = showKeywordLimitation &&
            (trigger == AiEscalationDisclosureTrigger.emergency ||
                trigger == AiEscalationDisclosureTrigger.high)
        ? resolveKeywordLimitationNote(ref)
        : null;
    final supportNote = showSupportAction ? resolveSupportVsVetNote(ref) : null;

    return Card(
      color: color,
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isEmergency ? Icons.emergency_outlined : Icons.person_search_outlined,
                  color: iconColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(text, style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
            if (keywordNote != null && keywordNote.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(keywordNote, style: theme.textTheme.labelSmall),
            ],
            if (showFindVetAction || showSupportAction || onRequestHumanReview != null) ...[
              const SizedBox(height: 12),
              if (showFindVetAction)
                FilledButton(
                  onPressed: () => context.push(AppRoutes.services),
                  child: Text(l10n.aiFindVet),
                ),
              if (onRequestHumanReview != null) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: onRequestHumanReview,
                  child: Text(l10n.aiRequestHumanReview),
                ),
              ],
              if (showSupportAction) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.push(AppRoutes.supportTicketCreate),
                  child: Text(l10n.aiEscalateSupport),
                ),
                if (supportNote != null && supportNote.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      supportNote,
                      style: theme.textTheme.labelSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Maps API / UI state to disclosure trigger for managed copy fallback.
AiEscalationDisclosureTrigger? escalationTriggerFromChat({
  required bool refused,
  required bool escalationRecommended,
  required bool humanRedirect,
}) {
  if (refused) return AiEscalationDisclosureTrigger.policyRefusal;
  if (escalationRecommended) return AiEscalationDisclosureTrigger.lowConfidence;
  if (humanRedirect) return AiEscalationDisclosureTrigger.humanReview;
  return null;
}

AiEscalationDisclosureTrigger? escalationTriggerFromTriage({
  required bool escalationRequired,
  required bool emergency,
}) {
  if (!escalationRequired) return null;
  return emergency
      ? AiEscalationDisclosureTrigger.emergency
      : AiEscalationDisclosureTrigger.high;
}

Future<void> requestAiHumanReview(WidgetRef ref) async {
  final ok = await ref.read(aiChatProvider.notifier).escalateToHuman();
  if (!ok) return;
  await ref.read(aiEscalationDisclosureProvider.notifier).refresh();
}
