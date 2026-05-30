import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../core/localization/translation_keys.dart';
import '../../../routing/app_routes.dart';
import 'livestock_providers.dart';
import 'widgets/health_status_chip.dart';
import 'widgets/livestock_feedback.dart';

class LivestockDetailPage extends ConsumerWidget {
  const LivestockDetailPage({super.key, required this.livestockId});

  final String livestockId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.tr;
    final detailAsync = ref.watch(livestockDetailProvider(livestockId));

    return detailAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.t(TranslationKeys.animalDetailTitle))),
        body: LivestockFeedback.loading(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.t(TranslationKeys.animalDetailTitle))),
        body: LivestockFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.invalidate(livestockDetailProvider(livestockId)),
        ),
      ),
      data: (profile) {
        return Scaffold(
          appBar: AppBar(
            title: Text(profile.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code),
                onPressed: () =>
                    context.push(AppRoutes.livestockQr(livestockId)),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () =>
                    context.push(AppRoutes.livestockEdit(livestockId)),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (profile.fromCache) LivestockFeedback.offlineHint(context),
              if (profile.photoUrl != null && profile.photoUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      profile.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.pets, size: 64),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _InfoRow(
                label: l10n.t(TranslationKeys.animalTypeLabel),
                value: profile.displaySpecies,
              ),
              _InfoRow(
                label: l10n.t(TranslationKeys.animalGenderLabel),
                value: profile.gender,
              ),
              _InfoRow(
                label: l10n.t(TranslationKeys.animalPurposeLabel),
                value: profile.purpose,
              ),
              Row(
                children: [
                  Text(l10n.t(TranslationKeys.animalHealthScore)),
                  const SizedBox(width: 8),
                  LivestockHealthStatusChip(status: profile.healthStatus),
                ],
              ),
              if (profile.weightKg != null)
                _InfoRow(
                  label: l10n.t(TranslationKeys.animalWeightLabel),
                  value: '${profile.weightKg!.toStringAsFixed(1)} kg',
                ),
              if (profile.earTagNumber != null &&
                  profile.earTagNumber!.isNotEmpty)
                _InfoRow(
                  label: l10n.t(TranslationKeys.animalTagLabel),
                  value: profile.earTagNumber!,
                ),
              if (profile.notes != null && profile.notes!.isNotEmpty)
                _InfoRow(
                  label: l10n.t(TranslationKeys.animalNotesLabel),
                  value: profile.notes!,
                ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        context.push(AppRoutes.livestockTimeline(livestockId)),
                    icon: const Icon(Icons.timeline),
                    label: Text(l10n.t(TranslationKeys.animalTimelineTitle)),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => context.push(
                      AppRoutes.dailyRation(livestockId),
                    ),
                    icon: const Icon(Icons.restaurant),
                    label: Text(l10n.t(TranslationKeys.recommendationTitle)),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => context.push(AppRoutes.vaccines),
                    icon: const Icon(Icons.vaccines_outlined),
                    label: Text(l10n.t(TranslationKeys.animalVaccinesShortcut)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
