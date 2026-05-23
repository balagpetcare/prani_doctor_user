import 'package:flutter/material.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../data/farm_dto.dart';

class FarmCard extends StatelessWidget {
  const FarmCard({super.key, required this.farm, required this.onTap});

  final Farm farm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (farm.coverPhotoUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(farm.coverPhotoUrl!, fit: BoxFit.cover),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(farm.name, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(farm.locationLabel, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Text(
                    l10n.farmCardStats(
                      farm.animalCount,
                      farm.activeAnimalCount,
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
