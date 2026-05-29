import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../core/localization/translation_keys.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/recommendation_dto.dart';
import '../data/recommendation_repository.dart';
import 'recommendation_providers.dart';
import 'widgets/ration_item_tile.dart';

class DailyRationPage extends ConsumerWidget {
  const DailyRationPage({super.key, required this.livestockId});

  final String livestockId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.tr;
    final recommendationAsync =
        ref.watch(dailyRecommendationProvider(livestockId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t(TranslationKeys.recommendationTitle))),
      body: recommendationAsync.when(
        loading: () => const AppLoadingView(),
        error: (e, _) => AppErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(dailyRecommendationProvider(livestockId)),
          retryLabel: l10n.t(TranslationKeys.retryLabel),
        ),
        data: (recommendation) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dailyRecommendationProvider(livestockId));
              await ref.read(dailyRecommendationProvider(livestockId).future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (recommendation.fromCache)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      l10n.t(TranslationKeys.phase4FeedOfflineHint),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                Text(
                  l10n.t(TranslationKeys.recommendationDailyIntake),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(recommendation.planDate),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    title: Text(l10n.t(TranslationKeys.recommendationEstimatedCost)),
                    trailing: Text(
                      '৳${recommendation.totals.estimatedCostBdt.toStringAsFixed(0)}',
                    ),
                    subtitle: Text(
                      l10n.t(
                        TranslationKeys.recommendationDryMatter,
                        {
                          'kg': recommendation.totals.dryMatterKg.toStringAsFixed(1),
                        },
                      ),
                    ),
                  ),
                ),
                if (recommendation.warnings.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.t(TranslationKeys.recommendationWarnings),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  ...recommendation.warnings.map(
                    (w) => ListTile(
                      leading: Icon(
                        Icons.warning_amber,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: Text(w),
                    ),
                  ),
                ],
                if (recommendation.intelligence != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.t(TranslationKeys.recommendationIntelligenceTitle),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  _ScoreGrid(
                    context: context,
                    scores: recommendation.intelligence!.scores,
                  ),
                  if (recommendation.intelligence!.explanations.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.t(TranslationKeys.recommendationExplanations),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    ...recommendation.intelligence!.explanations.map(
                      (e) => ListTile(
                        dense: true,
                        title: Text(e.ruleNameBn),
                        subtitle: Text(e.impactBn),
                      ),
                    ),
                  ],
                  if (recommendation.intelligence!.alternatives.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.t(TranslationKeys.recommendationAlternatives),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    ...recommendation.intelligence!.alternatives.map(
                      (alt) => ListTile(
                        dense: true,
                        title: Text(alt.nameBn),
                        subtitle: Text(alt.tradeoffBn),
                        trailing: Text(
                          '৳${alt.savingsBdt.toStringAsFixed(0)}',
                        ),
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 12),
                Text(
                  l10n.t(TranslationKeys.recommendationSuggestedFeed),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ...recommendation.items.map(
                  (item) => RationItemTile(item: item),
                ),
                if (recommendation.disclaimerBn.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    recommendation.disclaimerBn,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    final result = await ref
                        .read(recommendationRepositoryProvider)
                        .acceptRecommendation(
                          livestockId: livestockId,
                          planDate: recommendation.planDate,
                        );
                    if (!context.mounted) return;
                    result.when(
                      success: (_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.t(TranslationKeys.recommendationAccepted),
                            ),
                          ),
                        );
                      },
                      failure: (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.message)),
                        );
                      },
                    );
                  },
                  child: Text(l10n.t(TranslationKeys.recommendationAccept)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ScoreGrid extends StatelessWidget {
  const _ScoreGrid({required this.context, required this.scores});

  final BuildContext context;
  final RecommendationScoreBreakdown scores;

  String _pct(double v) => '${(v * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    final l10n = this.context.tr;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _ScoreChip(
              label: l10n.t(TranslationKeys.recommendationScoreOverall),
              value: _pct(scores.overall),
            ),
            _ScoreChip(
              label: l10n.t(TranslationKeys.recommendationScoreNutrition),
              value: _pct(scores.nutritionFit),
            ),
            _ScoreChip(
              label: l10n.t(TranslationKeys.recommendationScoreAffordability),
              value: _pct(scores.affordability),
            ),
            _ScoreChip(
              label: l10n.t(TranslationKeys.recommendationScoreSeasonal),
              value: _pct(scores.seasonalFit),
            ),
            _ScoreChip(
              label: l10n.t(TranslationKeys.recommendationScoreHealth),
              value: _pct(scores.healthSafety),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
    );
  }
}
