import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import 'farm_providers.dart';
import 'widgets/farm_feedback.dart';

class FarmDetailPage extends ConsumerWidget {
  const FarmDetailPage({super.key, required this.farmId});

  final String farmId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final detailAsync = ref.watch(farmDetailProvider(farmId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.farmDetailTitle),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.farmEdit(farmId)),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => FarmFeedback.loading(),
        error: (e, _) => FarmFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.invalidate(farmDetailProvider(farmId)),
        ),
        data: (detail) {
          final farm = detail.farm;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (detail.fromCache) FarmFeedback.offlineHint(context),
              if (farm.coverPhotoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(farm.coverPhotoUrl!, fit: BoxFit.cover),
                  ),
                ),
              const SizedBox(height: 16),
              Text(farm.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(farm.locationLabel),
              const SizedBox(height: 24),
              Text(l10n.farmSummaryTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _SummaryTile(label: l10n.dashboardTotalAnimals, value: '${farm.animalCount}'),
              _SummaryTile(
                label: l10n.farmActiveAnimals,
                value: '${farm.activeAnimalCount}',
              ),
              const SizedBox(height: 24),
              Text(l10n.farmRelatedAnimals, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              if (detail.animals.isEmpty)
                Text(l10n.farmNoAnimals)
              else
                ...detail.animals.map(
                  (animal) => ListTile(
                    leading: animal.photoUrl != null
                        ? CircleAvatar(backgroundImage: NetworkImage(animal.photoUrl!))
                        : const CircleAvatar(child: Icon(Icons.pets)),
                    title: Text(animal.name),
                    subtitle: Text(animal.animalType),
                    onTap: () => context.push(AppRoutes.animalDetail(animal.id)),
                  ),
                ),
            ],
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
