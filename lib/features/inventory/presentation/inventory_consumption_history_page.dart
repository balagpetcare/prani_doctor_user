import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_date_format.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../routing/app_routes.dart';
import '../../farm/presentation/farm_providers.dart';
import '../../feed/presentation/feed_providers.dart';

/// Shows feed consumption logs (feeding history) for the active farm.
class InventoryConsumptionHistoryPage extends ConsumerWidget {
  const InventoryConsumptionHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.tr;
    final farmId = ref.watch(activeFarmIdProvider).valueOrNull;
    final feedAsync = ref.watch(feedListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('inventoryConsumptionHistory'))),
      body: feedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (state) {
          final records = farmId == null
              ? state.records
              : state.records
                  .where((r) => r.farmRef == null || r.farmRef == farmId)
                  .toList();
          if (records.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.t('inventoryNoFeedingLogs')),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.push(AppRoutes.feedCreate),
                      child: Text(l10n.t('inventoryLogFeed')),
                    ),
                  ],
                ),
              ),
            );
          }
          final fmt = ref.watch(appDateFormatProvider);
          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final r = records[index];
              return ListTile(
                leading: const Icon(Icons.restaurant_outlined),
                title: Text('${r.feedType.name} · ${r.amount} ${r.unit.name}'),
                subtitle: Text(
                  '${fmt.date(r.recordedDate)} · ${r.targetLabel}',
                ),
                onTap: () => context.push(AppRoutes.feedDetail(r.id)),
              );
            },
          );
        },
      ),
    );
  }
}
