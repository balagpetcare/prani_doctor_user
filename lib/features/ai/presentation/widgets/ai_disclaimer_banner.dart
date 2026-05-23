import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

class AiDisclaimerBanner extends StatelessWidget {
  const AiDisclaimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MaterialBanner(
      content: Text(l10n.aiDisclaimer),
      leading: const Icon(Icons.info_outline),
      actions: const [SizedBox.shrink()],
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
