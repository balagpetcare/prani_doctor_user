import 'package:flutter/material.dart';

import '../../data/animal_dto.dart';

class AnimalCard extends StatelessWidget {
  const AnimalCard({super.key, required this.animal, required this.onTap});

  final AnimalProfile animal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundImage:
              animal.photoUrl != null ? NetworkImage(animal.photoUrl!) : null,
          child: animal.photoUrl == null ? const Icon(Icons.pets) : null,
        ),
        title: Text(animal.name),
        subtitle: Text(
          [
            animal.animalType ?? animal.species,
            if (animal.displayTag.isNotEmpty) 'Tag: ${animal.displayTag}',
            if (animal.breed != null && animal.breed!.isNotEmpty) animal.breed!,
          ].join(' · '),
        ),
        trailing: animal.active
            ? null
            : Text('Inactive', style: theme.textTheme.bodySmall),
      ),
    );
  }
}
