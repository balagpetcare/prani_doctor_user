import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import 'package:pranidoctor_user/l10n/app_localizations.dart';



import '../../../core/navigation/navigation_guard.dart';

import '../../../routing/app_routes.dart';

import '../data/animal_dto.dart';
import '../../home/presentation/widgets/home_card.dart';

import 'animal_navigation.dart';

import 'animal_providers.dart';

import 'widgets/animal_feedback.dart';



class AnimalDetailPage extends ConsumerWidget {

  const AnimalDetailPage({super.key, required this.animalId});



  final String animalId;



  Future<void> _confirmDeactivate(BuildContext context, WidgetRef ref) async {

    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(

      context: context,

      builder: (ctx) => AlertDialog(

        title: Text(l10n.animalDeactivateTitle),

        content: Text(l10n.animalDeactivateMessage),

        actions: [

          TextButton(

            onPressed: () => Navigator.pop(ctx, false),

            child: Text(l10n.cancel),

          ),

          FilledButton(

            onPressed: () => Navigator.pop(ctx, true),

            child: Text(l10n.animalDeactivateConfirm),

          ),

        ],

      ),

    );

    if (confirmed != true || !context.mounted) return;

    try {

      await ref.read(animalListProvider.notifier).deactivate(animalId);

      if (context.mounted) context.go(AppRoutes.animals);

    } catch (e) {

      if (context.mounted) {

        ScaffoldMessenger.of(

          context,

        ).showSnackBar(SnackBar(content: Text('$e')));

      }

    }

  }



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final l10n = AppLocalizations.of(context)!;

    final detailAsync = ref.watch(animalDetailProvider(animalId));

    return Scaffold(

      appBar: safeAppBar(

        context,

        title: Text(l10n.animalDetailTitle),

        actions: [

          if (detailAsync.valueOrNull?.animal.active ?? true)

            IconButton(

              onPressed: () => _confirmDeactivate(context, ref),

              icon: const Icon(Icons.archive_outlined),

              tooltip: l10n.animalDeactivateTitle,

            ),

          IconButton(

            onPressed: () => context.push(AppRoutes.animalEdit(animalId)),

            icon: const Icon(Icons.edit_outlined),

          ),

        ],

      ),

      body: detailAsync.when(

        loading: AnimalFeedback.loading,

        error: (e, _) => AnimalFeedback.error(

          context,

          message: e.toString(),

          onRetry: () => AnimalNavigation.refreshDetail(ref, animalId),

        ),

        data: (detail) {

          final animal = detail.animal;

          return RefreshIndicator(

            onRefresh: () async {

              AnimalNavigation.refreshDetail(ref, animalId);

              await ref.read(animalDetailProvider(animalId).future);

            },

            child: ListView(

              physics: const AlwaysScrollableScrollPhysics(),

              padding: const EdgeInsets.all(16),

              children: [

                if (detail.fromCache) AnimalFeedback.offlineHint(context),

                _HeroCard(animal: animal, l10n: l10n),

                const SizedBox(height: 16),

                _QuickActions(animalId: animalId, l10n: l10n),

                const SizedBox(height: 16),

                _SectionTitle(title: l10n.animalOverviewTitle),

                _OverviewGrid(animal: animal, l10n: l10n),

                const SizedBox(height: 16),

                _SectionTitle(title: l10n.animalTimelineTitle),

                ...detail.timeline.map(

                  (e) => ListTile(

                    leading: const Icon(Icons.timeline),

                    title: Text(e.title, maxLines: 2, overflow: TextOverflow.ellipsis),

                    subtitle: Text('${e.subtitle}\n${e.at.toLocal()}'),

                  ),

                ),

                const SizedBox(height: 8),

                _SectionTitle(title: l10n.animalVaccinesTitle),

                ListTile(

                  leading: const Icon(Icons.vaccines_outlined),

                  title: Text(l10n.animalNextReminder),

                  subtitle: Text(l10n.animalNextReminderPlaceholder),

                ),

                _SectionTitle(title: l10n.animalDocumentsTitle),

                ListTile(

                  leading: const Icon(Icons.folder_outlined),

                  title: Text(l10n.animalDocumentsEmpty),

                ),

                _SectionTitle(title: l10n.animalDoctorHistoryTitle),

                if (detail.history.isEmpty)

                  Padding(

                    padding: const EdgeInsets.symmetric(vertical: 8),

                    child: Text(l10n.animalNoHistory),

                  )

                else

                  ...detail.history.map(

                    (h) => ListTile(

                      leading: const Icon(Icons.medical_services_outlined),

                      title: Text(h.title, maxLines: 2, overflow: TextOverflow.ellipsis),

                      subtitle: Text(

                        '${h.status}${h.at != null ? ' · ${h.at!.toLocal()}' : ''}',

                      ),

                      onTap: () =>

                          context.push(AppRoutes.serviceRequestDetail(h.id)),

                    ),

                  ),

                _SectionTitle(title: l10n.animalReportsTitle),

                ListTile(

                  leading: const Icon(Icons.assessment_outlined),

                  title: Text(l10n.animalReportsTitle),

                  subtitle: Text(l10n.animalNoHistory),

                ),

                if (!animal.active)

                  Padding(

                    padding: const EdgeInsets.only(top: 12),

                    child: Chip(

                      avatar: const Icon(Icons.archive_outlined, size: 16),

                      label: Text(l10n.animalStatusInactive),

                    ),

                  ),

                const SizedBox(height: 24),

              ],

            ),

          );

        },

      ),

    );

  }

}



class _SectionTitle extends StatelessWidget {

  const _SectionTitle({required this.title});



  final String title;



  @override

  Widget build(BuildContext context) {

    return Padding(

      padding: const EdgeInsets.only(top: 8, bottom: 4),

      child: Text(title, style: Theme.of(context).textTheme.titleMedium),

    );

  }

}



class _HeroCard extends StatelessWidget {

  const _HeroCard({required this.animal, required this.l10n});



  final AnimalProfile animal;

  final AppLocalizations l10n;



  @override

  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return HomeSurfaceCard(

      elevated: true,

      padding: EdgeInsets.zero,

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [

          if (animal.photoUrl != null)

            AspectRatio(

              aspectRatio: 16 / 9,

              child: ClipRRect(

                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),

                child: HomeCachedImage(

                  url: animal.photoUrl,

                  fit: BoxFit.cover,

                  fallbackIcon: Icons.pets,

                  fallbackText: animal.name,

                ),

              ),

            ),

          Padding(

            padding: const EdgeInsets.all(16),

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(

                  animal.name,

                  style: theme.textTheme.headlineSmall,

                  maxLines: 2,

                  overflow: TextOverflow.ellipsis,

                ),

                const SizedBox(height: 4),

                Text(

                  '${animal.animalType ?? animal.species} · ${animal.category}',

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                ),

                const SizedBox(height: 12),

                Row(

                  children: [

                    Expanded(

                      child: _MetricChip(

                        icon: Icons.favorite_outline,

                        label: l10n.animalHealthScore,

                        value: l10n.animalHealthScorePlaceholder,

                      ),

                    ),

                    const SizedBox(width: 8),

                    Expanded(

                      child: _MetricChip(

                        icon: Icons.qr_code_2_outlined,

                        label: l10n.animalQrCode,

                        value: l10n.animalQrPlaceholder,

                      ),

                    ),

                  ],

                ),

              ],

            ),

          ),

        ],

      ),

    );

  }

}



class _MetricChip extends StatelessWidget {

  const _MetricChip({

    required this.icon,

    required this.label,

    required this.value,

  });



  final IconData icon;

  final String label;

  final String value;



  @override

  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(

        color: Theme.of(context).colorScheme.surfaceContainerHighest,

        borderRadius: BorderRadius.circular(12),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Icon(icon, size: 20),

          const SizedBox(height: 4),

          Text(label, style: Theme.of(context).textTheme.labelSmall),

          Text(

            value,

            style: Theme.of(context).textTheme.bodySmall,

            maxLines: 2,

            overflow: TextOverflow.ellipsis,

          ),

        ],

      ),

    );

  }

}



class _QuickActions extends StatelessWidget {

  const _QuickActions({required this.animalId, required this.l10n});



  final String animalId;

  final AppLocalizations l10n;



  @override

  Widget build(BuildContext context) {

    return Wrap(

      spacing: 8,

      runSpacing: 8,

      children: [

        ActionChip(

          avatar: const Icon(Icons.medical_services_outlined, size: 18),

          label: Text(l10n.dashboardRecordHealth),

          onPressed: () => context.push(AppRoutes.healthHistory),

        ),

        ActionChip(

          avatar: const Icon(Icons.vaccines_outlined, size: 18),

          label: Text(l10n.animalVaccinesShortcut),

          onPressed: () => context.push(AppRoutes.vaccines),

        ),

        ActionChip(

          avatar: const Icon(Icons.healing_outlined, size: 18),

          label: Text(l10n.animalTreatmentsShortcut),

          onPressed: () => context.push(AppRoutes.treatments),

        ),

        ActionChip(

          avatar: const Icon(Icons.edit_outlined, size: 18),

          label: Text(l10n.animalEditTitle),

          onPressed: () => context.push(AppRoutes.animalEdit(animalId)),

        ),

      ],

    );

  }

}



class _OverviewGrid extends StatelessWidget {

  const _OverviewGrid({required this.animal, required this.l10n});



  final AnimalProfile animal;

  final AppLocalizations l10n;



  @override

  Widget build(BuildContext context) {

    final items = <String>[];

    if (animal.displayTag.isNotEmpty) {

      items.add('${l10n.animalTagLabel}: ${animal.displayTag}');

    }

    if (animal.breed != null && animal.breed!.isNotEmpty) {

      items.add('${l10n.animalBreedLabel}: ${animal.breed}');

    }

    if (animal.weightKg != null) {

      items.add('${l10n.animalWeightLabel}: ${animal.weightKg} kg');

    }

    if (animal.ageYears != null) {

      items.add('${l10n.animalAgeLabel}: ${animal.ageYears}');

    }

    if (animal.gender != null && animal.gender!.isNotEmpty) {

      items.add('${l10n.animalGenderLabel}: ${animal.gender}');

    }

    if (animal.notes != null && animal.notes!.trim().isNotEmpty) {

      items.add('${l10n.animalNotesLabel}: ${animal.notes}');

    }



    return HomeSurfaceCard(

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: items

            .map(

              (line) => Padding(

                padding: const EdgeInsets.symmetric(vertical: 4),

                child: Text(line, maxLines: 3, overflow: TextOverflow.ellipsis),

              ),

            )

            .toList(),

      ),

    );

  }

}


