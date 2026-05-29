import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../core/navigation/navigation_guard.dart';
import '../../../routing/app_routes.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../data/farm_dto.dart';
import '../data/farm_location.dart';
import 'farm_navigation.dart';
import 'farm_providers.dart';
import 'widgets/farm_feedback.dart';

String _formatLocationLabel(Farm farm) {
  final location = FarmLocation.fromAddress(
    farm.address,
    areaLabel: farm.locationLabel,
  );
  final village = location.villageName?.trim();
  if (village != null && village.isNotEmpty) {
    final label = farm.locationLabel.trim();
    if (label.isEmpty || label == village) return village;
    if (!label.contains(village)) return '$village · $label';
  }
  return farm.locationLabel;
}

class FarmDetailPage extends ConsumerWidget {
  const FarmDetailPage({super.key, required this.farmId});

  final String farmId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final detailAsync = ref.watch(farmDetailProvider(farmId));

    return Scaffold(
      appBar: safeAppBar(
        context,
        title: Text(l10n.farmDetailTitle),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.farmSettings(farmId)),
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.farmSettingsTitle,
          ),
          IconButton(
            onPressed: () => context.push(AppRoutes.farmEdit(farmId)),
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.farmEditTitle,
          ),
        ],
      ),
      body: detailAsync.when(
        loading: FarmFeedback.loading,
        error: (e, _) => FarmFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => FarmNavigation.refreshFarmDetail(ref, farmId),
        ),
        data: (detail) {
          final farm = detail.farm;
          return RefreshIndicator(
            onRefresh: () async {
              FarmNavigation.refreshFarmDetail(ref, farmId);
              await ref.read(farmDetailProvider(farmId).future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (detail.fromCache) FarmFeedback.offlineHint(context),
                if (farm.coverPhotoUrl != null &&
                    farm.coverPhotoUrl!.trim().isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: AppNetworkImage(
                        url: farm.coverPhotoUrl,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(12),
                        placeholderIcon: Icons.agriculture_outlined,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  farm.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _formatLocationLabel(farm),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.pets, size: 18),
                      label: Text(l10n.dashboardAddAnimal),
                      onPressed: () => context.push(AppRoutes.animalCreate),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.grass_outlined, size: 18),
                      label: Text(l10n.drawerFatteningSection),
                      onPressed: () =>
                          context.push(AppRoutes.farmFattening(farmId)),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.edit_outlined, size: 18),
                      label: Text(l10n.farmEditTitle),
                      onPressed: () => context.push(AppRoutes.farmEdit(farmId)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.farmSummaryTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _SummaryTile(
                  label: l10n.dashboardTotalAnimals,
                  value: '${farm.animalCount}',
                ),
                _SummaryTile(
                  label: l10n.farmActiveAnimals,
                  value: '${farm.activeAnimalCount}',
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.farmRelatedAnimals,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (detail.animals.isEmpty)
                  Text(l10n.farmNoAnimals)
                else
                  ...detail.animals.map(
                    (animal) => ListTile(
                      leading: animal.photoUrl != null
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(animal.photoUrl!),
                            )
                          : const CircleAvatar(child: Icon(Icons.pets)),
                      title: Text(animal.name),
                      subtitle: Text(animal.animalType),
                      onTap: () =>
                          context.push(AppRoutes.animalDetail(animal.id)),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Text(value, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
