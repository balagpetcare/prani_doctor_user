import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import '../data/ai_dto.dart';
import 'ai_providers.dart';
import 'widgets/ai_escalation_disclosure_strip.dart';
import 'widgets/triage_card.dart';

class AiResultPage extends ConsumerWidget {
  const AiResultPage({super.key, this.result});

  final TriageResultModel? result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final triage = result ?? ref.watch(aiChatProvider).value?.triageResult;
    final trigger = triage?.escalationFields?.trigger ??
        (triage != null
            ? escalationTriggerFromTriage(
                escalationRequired: triage.escalationRequired,
                emergency: triage.emergency,
              )
            : null);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aiResultTitle)),
      body: triage == null
          ? Center(child: Text(l10n.aiResultEmpty))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TriageCard(result: triage),
                if (trigger != null) ...[
                  const SizedBox(height: 8),
                  AiEscalationDisclosureStrip(
                    trigger: trigger,
                    apiDisclosure: triage.escalationFields?.disclosure,
                    showKeywordLimitation: true,
                    onRequestHumanReview: () => requestAiHumanReview(ref),
                  ),
                ],
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => context.push(AppRoutes.aiChat),
                  child: Text(l10n.aiAskTitle),
                ),
              ],
            ),
    );
  }
}

TriageResultModel? triageResultFromExtra(Object? extra) {
  return extra is TriageResultModel ? extra : null;
}
