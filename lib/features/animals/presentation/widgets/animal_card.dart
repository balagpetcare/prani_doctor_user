import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../data/animal_dto.dart';

class AnimalCard extends StatelessWidget {
  const AnimalCard({super.key, required this.animal, required this.onTap});

  final AnimalProfile animal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundImage: animal.primaryImageUrl != null
              ? NetworkImage(animal.primaryImageUrl!)
              : null,
          child: animal.primaryImageUrl == null ? const Icon(Icons.pets) : null,
        ),
        title: Text(animal.name),
        subtitle: Text(
          [
            animal.animalType ?? animal.species,
            if (animal.displayTag.isNotEmpty)
              '${l10n.animalTagLabel}: ${animal.displayTag}',
            if (animal.breed != null && animal.breed!.isNotEmpty) animal.breed!,
          ].join(' · '),
        ),
        trailing: animal.active
            ? null
            : Text(l10n.animalStatusInactive, style: theme.textTheme.bodySmall),
      ),
    );
  }
}
