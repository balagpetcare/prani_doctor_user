import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../data/animal_breeds.dart';

class BreedSearchField extends StatelessWidget {
  const BreedSearchField({
    super.key,
    required this.animalType,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String animalType;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final breeds = AnimalBreeds.forType(animalType);

    return Autocomplete<String>(
      initialValue: TextEditingValue(text: value ?? ''),
      optionsBuilder: (query) {
        final q = query.text.trim().toLowerCase();
        if (q.isEmpty) return breeds;
        return breeds.where((b) => b.toLowerCase().contains(q));
      },
      onSelected: (selection) => onChanged(selection),
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        if (value != null && controller.text != value) {
          controller.text = value!;
        }
        return TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          decoration: InputDecoration(
            labelText: l10n.animalBreedLabel,
            hintText: l10n.animalBreedSearchHint,
            suffixIcon: const Icon(Icons.search),
          ),
          onChanged: (text) {
            final trimmed = text.trim();
            onChanged(trimmed.isEmpty ? null : trimmed);
          },
        );
      },
    );
  }
}
