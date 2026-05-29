import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ecosystem/presentation/active_farm_ref_provider.dart';
import '../data/analytics_dto.dart';
import '../data/analytics_repository.dart';

final livestockDashboardProvider =
    FutureProvider.autoDispose<LivestockDashboardMetrics?>((ref) async {
  final farmRef = ref.watch(activeFarmRefProvider);
  if (farmRef == null || farmRef.isEmpty) return null;
  final result = await ref
      .read(livestockAnalyticsRepositoryProvider)
      .getDashboard(farmRef: farmRef);
  return result.when(success: (m) => m, failure: (e) => throw e);
});

final feedEfficiencyProvider =
    FutureProvider.autoDispose<FeedEfficiencyMetrics?>((ref) async {
  final farmRef = ref.watch(activeFarmRefProvider);
  if (farmRef == null || farmRef.isEmpty) return null;
  final result = await ref
      .read(livestockAnalyticsRepositoryProvider)
      .getFeedEfficiency(farmRef: farmRef);
  return result.when(success: (m) => m, failure: (e) => throw e);
});

final profitLossProvider =
    FutureProvider.autoDispose<ProfitLossMetrics?>((ref) async {
  final farmRef = ref.watch(activeFarmRefProvider);
  if (farmRef == null || farmRef.isEmpty) return null;
  final result = await ref
      .read(livestockAnalyticsRepositoryProvider)
      .getProfitLoss(farmRef: farmRef);
  return result.when(success: (m) => m, failure: (e) => throw e);
});
