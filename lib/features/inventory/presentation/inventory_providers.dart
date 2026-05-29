import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../feed/data/feed_dto.dart';
import '../../feed/presentation/feed_providers.dart';
import '../data/inventory_dto.dart';
import '../data/inventory_repository.dart';

class InventoryListState {
  const InventoryListState({
    required this.result,
    this.isRefreshing = false,
  });

  final InventoryListResult result;
  final bool isRefreshing;
}

final inventoryDashboardProvider = FutureProvider.autoDispose
    .family<InventorySummary, String>((ref, farmRef) async {
      final repo = ref.watch(inventoryRepositoryProvider);
      final cached = await repo.readCachedSummary(farmRef);
      if (cached != null) {
        unawaited(repo.getSummary(farmRef, forceRefresh: true));
        return cached;
      }
      final result = await repo.getSummary(farmRef);
      return result.when(
        success: (s) => s,
        failure: (e) => throw Exception(e.message),
      );
    });

final inventoryFeedListProvider = FutureProvider.autoDispose
    .family<InventoryListState, String>((ref, farmRef) async {
      final repo = ref.watch(inventoryRepositoryProvider);
      final cached = await repo.readCachedFeedList(farmRef);
      if (cached != null) {
        unawaited(_refreshFeedList(ref, farmRef));
        return InventoryListState(result: cached);
      }
      return _refreshFeedList(ref, farmRef);
    });

Future<InventoryListState> _refreshFeedList(Ref ref, String farmRef) async {
  final repo = ref.read(inventoryRepositoryProvider);
  final result = await repo.listFeed(farmRef, forceRefresh: true);
  return result.when(
    success: (r) => InventoryListState(result: r),
    failure: (e) => throw Exception(e.message),
  );
}

final inventoryMedicineListProvider = FutureProvider.autoDispose
    .family<InventoryListState, String>((ref, farmRef) async {
      final repo = ref.watch(inventoryRepositoryProvider);
      final cached = await repo.readCachedMedicineList(farmRef);
      if (cached != null) {
        unawaited(_refreshMedicineList(ref, farmRef));
        return InventoryListState(result: cached);
      }
      return _refreshMedicineList(ref, farmRef);
    });

Future<InventoryListState> _refreshMedicineList(Ref ref, String farmRef) async {
  final repo = ref.read(inventoryRepositoryProvider);
  final result = await repo.listMedicine(farmRef, forceRefresh: true);
  return result.when(
    success: (r) => InventoryListState(result: r),
    failure: (e) => throw Exception(e.message),
  );
}

final inventoryRecentFeedLogsProvider = Provider.autoDispose
    .family<List<FeedRecord>, String>((ref, farmRef) {
      // Only rebuild when the records list itself changes, not when pagination
      // metadata (total, page, hasMore, isRefreshing) changes.
      final records = ref.watch(
        feedListProvider.select((s) => s.valueOrNull?.records),
      );
      if (records == null) return const <FeedRecord>[];
      return records
          .where((r) => r.farmRef == null || r.farmRef == farmRef)
          .toList();
    });
