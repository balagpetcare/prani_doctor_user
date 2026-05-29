import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../service_requests/presentation/service_request_status_chip.dart';
import '../data/outbox_item.dart';
import '../data/sync_coordinator.dart';
import '../offline_providers.dart';

class OfflineQueuePanel extends ConsumerWidget {
  const OfflineQueuePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final outboxAsync = ref.watch(_localOutboxItemsProvider);
    final pendingAsync = ref.watch(offlineSyncStatusProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.offlineSyncTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            pendingAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => Text(l10n.offlineSyncError),
              data: (count) => Text(l10n.offlinePendingCount(count)),
            ),
            const SizedBox(height: 12),
            outboxAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (items) {
                if (items.isEmpty) {
                  return Text(l10n.offlineQueueEmpty);
                }
                return Column(
                  children: items
                      .map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(_itemLabel(l10n, item)),
                          subtitle: Text(
                            item.lastError ?? formatTimestamp(item.createdAt),
                          ),
                          trailing: item.isDead
                              ? Chip(label: Text(l10n.offlineDead))
                              : null,
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await ref
                          .read(syncCoordinatorProvider)
                          .syncNow(foreground: true);
                      ref.invalidate(_localOutboxItemsProvider);
                      ref.invalidate(offlineSyncStatusProvider);
                      ref.invalidate(localOutboxCountProvider);
                    },
                    child: Text(l10n.syncNow),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () async {
                      await ref
                          .read(syncCoordinatorProvider)
                          .retryDead(includeDead: true);
                      ref.invalidate(_localOutboxItemsProvider);
                      ref.invalidate(offlineSyncStatusProvider);
                      ref.invalidate(localOutboxCountProvider);
                    },
                    child: Text(l10n.retryFailed),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _itemLabel(AppLocalizations l10n, OutboxItem item) {
    switch (item.kind) {
      case OutboxKind.serviceRequest:
        return l10n.offlineItemServiceRequest;
      case OutboxKind.offlineLead:
        return l10n.offlineItemLead;
      case OutboxKind.profilePatch:
        return l10n.offlineItemProfile;
      case OutboxKind.animalCreate:
      case OutboxKind.animalPatch:
        return l10n.selectAnimal;
      case OutboxKind.livestockCreate:
        return 'Livestock sync pending';
      case OutboxKind.phase4FeedPurchase:
      case OutboxKind.phase4FeedConsumption:
        return 'Feed stock sync pending';
      case OutboxKind.batchCreate:
      case OutboxKind.batchPatch:
      case OutboxKind.batchMove:
      case OutboxKind.batchMerge:
        return l10n.offlineItemBatch;
      case OutboxKind.fatteningBatchCreate:
      case OutboxKind.fatteningBatchAddAnimals:
      case OutboxKind.fatteningBatchStart:
      case OutboxKind.fatteningWeightCreate:
        return l10n.drawerFatteningSection;
      case OutboxKind.milkCreate:
      case OutboxKind.milkPatch:
      case OutboxKind.milkDelete:
        return l10n.offlineItemMilk;
      case OutboxKind.feedCreate:
      case OutboxKind.feedPatch:
      case OutboxKind.feedDelete:
        return l10n.offlineItemFeed;
      case OutboxKind.inventoryAdd:
      case OutboxKind.inventoryConsume:
        return 'Inventory sync pending';
      case OutboxKind.financeExpenseCreate:
      case OutboxKind.financeExpensePatch:
      case OutboxKind.financeExpenseDelete:
        return l10n.offlineItemFinanceExpense;
      case OutboxKind.financeIncomeCreate:
      case OutboxKind.financeIncomePatch:
      case OutboxKind.financeIncomeDelete:
        return l10n.offlineItemFinanceIncome;
      case OutboxKind.healthCreate:
      case OutboxKind.healthPatch:
      case OutboxKind.healthDelete:
        return l10n.offlineItemHealth;
      case OutboxKind.vaccineCreate:
      case OutboxKind.vaccinePatch:
      case OutboxKind.vaccineDelete:
        return l10n.offlineItemVaccine;
      case OutboxKind.treatmentCreate:
      case OutboxKind.treatmentPatch:
      case OutboxKind.treatmentDelete:
        return l10n.offlineItemTreatment;
      case OutboxKind.supportTicketCreate:
      case OutboxKind.supportTicketReply:
      case OutboxKind.supportTicketPatch:
        return l10n.offlineItemSupport;
      case OutboxKind.aiChatMessage:
        return l10n.offlineItemAiChat;
      case OutboxKind.settingsSync:
        return l10n.offlineItemSettingsSync;
    }
  }
}

final _localOutboxItemsProvider = FutureProvider<List<OutboxItem>>((ref) async {
  return ref.read(outboxServiceProvider).listAll();
});
