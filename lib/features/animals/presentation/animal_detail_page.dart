import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import 'animal_providers.dart';
import 'widgets/animal_feedback.dart';

class AnimalDetailPage extends ConsumerWidget {
  const AnimalDetailPage({super.key, required this.animalId});

  final String animalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final detailAsync = ref.watch(animalDetailProvider(animalId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.animalDetailTitle),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.animalEdit(animalId)),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => AnimalFeedback.loading(),
        error: (e, _) => AnimalFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.invalidate(animalDetailProvider(animalId)),
        ),
        data: (detail) {
          final animal = detail.animal;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (detail.fromCache) AnimalFeedback.offlineHint(context),
              if (animal.photoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.network(animal.photoUrl!, fit: BoxFit.cover),
                  ),
                ),
              const SizedBox(height: 16),
              Text(animal.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('${animal.animalType ?? animal.species} · ${animal.category}'),
              if (animal.displayTag.isNotEmpty) Text('${l10n.animalTagLabel}: ${animal.displayTag}'),
              if (animal.breed != null && animal.breed!.isNotEmpty)
                Text('${l10n.animalBreedLabel}: ${animal.breed}'),
              if (animal.weightKg != null) Text('${l10n.animalWeightLabel}: ${animal.weightKg} kg'),
              const SizedBox(height: 24),
              Text(l10n.animalTimelineTitle, style: Theme.of(context).textTheme.titleMedium),
              ...detail.timeline.map(
                (e) => ListTile(
                  leading: const Icon(Icons.timeline),
                  title: Text(e.title),
                  subtitle: Text('${e.subtitle}\n${e.at.toLocal()}'),
                ),
              ),
              const SizedBox(height: 16),
              Text(l10n.animalHistoryTitle, style: Theme.of(context).textTheme.titleMedium),
              if (detail.history.isEmpty)
                Text(l10n.animalNoHistory)
              else
                ...detail.history.map(
                  (h) => ListTile(
                    leading: const Icon(Icons.medical_services_outlined),
                    title: Text(h.title),
                    subtitle: Text('${h.status}${h.at != null ? ' · ${h.at!.toLocal()}' : ''}'),
                    onTap: () => context.push(AppRoutes.serviceRequestDetail(h.id)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
