import 'package:flutter/material.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/localization/translation_keys.dart';
import '../../data/livestock_dto.dart';
import 'health_status_chip.dart';

class LivestockCard extends StatelessWidget {
  const LivestockCard({
    super.key,
    required this.profile,
    required this.onTap,
  });

  final LivestockProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.tr;
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage:
                    profile.photoUrl != null && profile.photoUrl!.isNotEmpty
                    ? NetworkImage(profile.photoUrl!)
                    : null,
                child: profile.photoUrl == null || profile.photoUrl!.isEmpty
                    ? const Icon(Icons.pets)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.displaySpecies,
                      style: theme.textTheme.bodySmall,
                    ),
                    if (profile.earTagNumber != null &&
                        profile.earTagNumber!.isNotEmpty)
                      Text(
                        l10n.t(
                          TranslationKeys.livestockEarTag,
                          {'tag': profile.earTagNumber!},
                        ),
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              LivestockHealthStatusChip(status: profile.healthStatus),
            ],
          ),
        ),
      ),
    );
  }
}
