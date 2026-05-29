import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../../routing/app_routes.dart';
import '../data/fattening_qurbani_dto.dart';
import 'fattening_providers.dart';
import 'widgets/fattening_feedback.dart';

class FatteningBatchQurbaniPage extends ConsumerWidget {
  const FatteningBatchQurbaniPage({
    super.key,
    required this.farmId,
    required this.batchId,
  });

  final String farmId;
  final String batchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final qurbaniAsync = ref.watch(fatteningQurbaniProvider(batchId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.fatteningQurbaniTitle)),
      body: qurbaniAsync.when(
        loading: FatteningFeedback.loading,
        error: (e, _) => FatteningFeedback.error(
          context,
          error: e,
          onRetry: () => ref.invalidate(fatteningQurbaniProvider(batchId)),
        ),
        data: (dashboard) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(fatteningQurbaniProvider(batchId));
              await ref.read(fatteningQurbaniProvider(batchId).future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (dashboard.fromCache) FatteningFeedback.offlineHint(context),
                _CountdownCard(countdown: dashboard.countdown, l10n: l10n),
                const SizedBox(height: 16),
                _ReadinessCard(readiness: dashboard.readiness, l10n: l10n),
                const SizedBox(height: 24),
                Text(
                  l10n.fatteningQurbaniAnimals,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (dashboard.animals.isEmpty)
                  Text(l10n.fatteningNoAnimalsYet)
                else
                  ...dashboard.animals.map(
                    (a) => _AnimalReadinessTile(animal: a, l10n: l10n),
                  ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => context.push(
                    AppRoutes.fatteningBatchProgress(farmId, batchId),
                  ),
                  icon: const Icon(Icons.trending_up_outlined),
                  label: Text(l10n.fatteningProgressTitle),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CountdownCard extends StatelessWidget {
  const _CountdownCard({required this.countdown, required this.l10n});

  final QurbaniCountdown countdown;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (countdown.targetDate == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l10n.fatteningQurbaniSetTargetDate),
        ),
      );
    }

    final days = countdown.daysRemaining ?? 0;
    final displayDays = days.abs();

    return Card(
      color: countdown.isPast
          ? theme.colorScheme.errorContainer
          : theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              l10n.fatteningQurbaniCountdown,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '$displayDays',
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              countdown.label ?? l10n.fatteningQurbaniDaysLabel(displayDays),
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (countdown.targetDate != null) ...[
              const SizedBox(height: 8),
              Text(
                l10n.fatteningQurbaniTargetOn(countdown.targetDate!),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({required this.readiness, required this.l10n});

  final QurbaniReadinessSummary readiness;
  final AppLocalizations l10n;

  String _statusLabel(QurbaniReadinessStatus status) {
    return switch (status) {
      QurbaniReadinessStatus.ready => l10n.fatteningQurbaniStatusReady,
      QurbaniReadinessStatus.atRisk => l10n.fatteningQurbaniStatusAtRisk,
      QurbaniReadinessStatus.overdue => l10n.fatteningQurbaniStatusOverdue,
      QurbaniReadinessStatus.notStarted => l10n.fatteningQurbaniStatusNotStarted,
      QurbaniReadinessStatus.onTrack => l10n.fatteningQurbaniStatusOnTrack,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.fatteningQurbaniReadiness,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: readiness.scorePct / 100,
                        strokeWidth: 8,
                      ),
                      Center(
                        child: Text(
                          '${readiness.scorePct.round()}%',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Chip(label: Text(_statusLabel(readiness.status))),
                      if (readiness.weightProgressPct != null)
                        Text(
                          l10n.fatteningQurbaniWeightProgress(
                            readiness.weightProgressPct!,
                          ),
                        ),
                      if (readiness.timeProgressPct != null)
                        Text(
                          l10n.fatteningQurbaniTimeProgress(
                            readiness.timeProgressPct!,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimalReadinessTile extends StatelessWidget {
  const _AnimalReadinessTile({required this.animal, required this.l10n});

  final QurbaniAnimalReadiness animal;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(animal.animalName, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: animal.progressPct / 100),
            const SizedBox(height: 4),
            Text(
              l10n.fatteningQurbaniAnimalProgress(
                animal.currentWeightKg ?? '—',
                animal.targetWeightKg.round(),
                animal.progressPct,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
