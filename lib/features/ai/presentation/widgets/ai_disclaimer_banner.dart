import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../data/ai_disclaimer_dto.dart';
import '../ai_disclaimer_providers.dart';

class AiDisclaimerBanner extends ConsumerWidget {
  const AiDisclaimerBanner({
    super.key,
    this.feature,
    this.fallback,
  });

  final AiDisclaimerFeature? feature;
  final String? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(aiDisclaimerLocaleProvider);
    final managed = feature == null
        ? ref.watch(aiDisclaimerBannerTextProvider)
        : ref.watch(aiDisclaimerContextualProvider(feature!));
    final text = (managed != null && managed.isNotEmpty)
        ? managed
        : (fallback ?? l10n.aiDisclaimer);

    return MaterialBanner(
      content: Text(text),
      leading: const Icon(Icons.info_outline),
      actions: const [SizedBox.shrink()],
    );
  }
}

class AiDisclaimerFooter extends ConsumerWidget {
  const AiDisclaimerFooter({super.key, required this.feature, this.fallback});

  final AiDisclaimerFeature feature;
  final String? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final managed = ref.watch(aiDisclaimerContextualProvider(feature));
    final text = (managed != null && managed.isNotEmpty)
        ? managed
        : (fallback ?? l10n.aiDisclaimer);

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}

class AiSuggestionChips extends StatelessWidget {
  const AiSuggestionChips({super.key, required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final suggestions = [
      l10n.aiSuggestionFeed,
      l10n.aiSuggestionVaccine,
      l10n.aiSuggestionSymptoms,
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: suggestions
            .map(
              (text) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(text),
                  onPressed: () => onSelected(text),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
