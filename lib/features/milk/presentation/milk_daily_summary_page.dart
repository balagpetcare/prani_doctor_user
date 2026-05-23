import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import 'milk_providers.dart';
import 'widgets/milk_feedback.dart';

class MilkDailySummaryPage extends ConsumerWidget {
  const MilkDailySummaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final date = ref.watch(milkSummaryDateProvider);
    final summaryAsync = ref.watch(milkSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.milkSummaryTitle)),
      body: summaryAsync.when(
        loading: MilkFeedback.loading,
        error: (e, _) => MilkFeedback.error(
          context,
          message: e.toString(),
          onRetry: () => ref.invalidate(milkSummaryProvider),
        ),
        data: (summary) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(milkSummaryProvider);
              await ref.read(milkSummaryProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (summary.fromCache) MilkFeedback.offlineHint(context),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        ref.read(milkSummaryDateProvider.notifier).state = date
                            .subtract(const Duration(days: 1));
                        ref.invalidate(milkSummaryProvider);
                      },
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        date.toLocal().toString().split(' ').first,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      onPressed:
                          date.isBefore(
                            DateTime.now().subtract(const Duration(days: 1)),
                          )
                          ? () {
                              ref.read(milkSummaryDateProvider.notifier).state =
                                  date.add(const Duration(days: 1));
                              ref.invalidate(milkSummaryProvider);
                            }
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.milkTodayTotal,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.milkLiters(summary.totalLiters),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${l10n.milkSessionMorning}: ${summary.morningLiters.toStringAsFixed(2)} L',
                        ),
                        Text(
                          '${l10n.milkSessionEvening}: ${summary.eveningLiters.toStringAsFixed(2)} L',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.milkPerAnimalTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (summary.byAnimal.isEmpty)
                  Text(l10n.milkEmpty)
                else
                  ...summary.byAnimal.map(
                    (a) => ListTile(
                      leading: const Icon(Icons.pets),
                      title: Text(a.animalName),
                      subtitle: Text(
                        '${l10n.milkLiters(a.totalLiters)} · ${l10n.milkSessionMorning} ${a.morningLiters.toStringAsFixed(1)} · ${l10n.milkSessionEvening} ${a.eveningLiters.toStringAsFixed(1)}',
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  l10n.milkPerDayTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (summary.byDay.isEmpty)
                  Text(l10n.milkEmpty)
                else
                  ...summary.byDay.map(
                    (d) => ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(d.date),
                      subtitle: Text(
                        '${l10n.milkLiters(d.totalLiters)} · ${l10n.milkSessionMorning} ${d.morningLiters.toStringAsFixed(1)} · ${l10n.milkSessionEvening} ${d.eveningLiters.toStringAsFixed(1)}',
                      ),
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
