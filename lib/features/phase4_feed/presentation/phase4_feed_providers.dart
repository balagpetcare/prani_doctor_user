import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ecosystem/presentation/active_farm_ref_provider.dart';
import '../data/phase4_feed_dto.dart';
import '../data/phase4_feed_repository.dart';

final phase4FeedSearchProvider = StateProvider<String>((ref) => '');

final phase4FeedItemsProvider = FutureProvider.autoDispose((ref) async {
  ref.watch(phase4FeedSearchProvider);
  final result = await ref.read(phase4FeedRepositoryProvider).listFeedItems(
    search: ref.read(phase4FeedSearchProvider),
  );
  return result.when(success: (page) => page, failure: (e) => throw e);
});

final phase4FeedItemDetailProvider = FutureProvider.autoDispose
    .family<Phase4FeedItem, String>((ref, id) async {
      final result = await ref.read(phase4FeedRepositoryProvider).getFeedItem(id);
      return result.when(success: (item) => item, failure: (e) => throw e);
    });

final phase4FeedInventoryProvider = FutureProvider.autoDispose((ref) async {
  final farmRef = ref.watch(activeFarmRefProvider);
  if (farmRef == null || farmRef.isEmpty) {
    return const Phase4FeedPageResult<Phase4FeedInventoryItem>(
      items: [],
      page: 1,
      pageSize: 20,
      total: 0,
      hasMore: false,
    );
  }
  final result = await ref
      .read(phase4FeedRepositoryProvider)
      .listInventory(farmRef: farmRef);
  return result.when(success: (page) => page, failure: (e) => throw e);
});

final phase4LowStockAlertsProvider = FutureProvider.autoDispose((ref) async {
  final farmRef = ref.watch(activeFarmRefProvider);
  if (farmRef == null || farmRef.isEmpty) return <Phase4LowStockAlert>[];
  final result = await ref
      .read(phase4FeedRepositoryProvider)
      .listLowStockAlerts(farmRef);
  return result.when(success: (alerts) => alerts, failure: (e) => throw e);
});

final phase4FeedConsumptionProvider = FutureProvider.autoDispose((ref) async {
  final farmRef = ref.watch(activeFarmRefProvider);
  if (farmRef == null || farmRef.isEmpty) {
    return const Phase4FeedPageResult<Phase4FeedConsumptionRecord>(
      items: [],
      page: 1,
      pageSize: 20,
      total: 0,
      hasMore: false,
    );
  }
  final result = await ref
      .read(phase4FeedRepositoryProvider)
      .listConsumption(farmRef: farmRef);
  return result.when(success: (page) => page, failure: (e) => throw e);
});
