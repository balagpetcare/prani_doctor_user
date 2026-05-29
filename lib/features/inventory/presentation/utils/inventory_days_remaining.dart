import '../../../feed/data/feed_dto.dart';
import '../../data/inventory_dto.dart';

/// Estimates days of feed remaining from recent feeding logs (same farm + feed type).
int? estimateFeedDaysRemaining({
  required InventoryItem item,
  required List<FeedRecord> recentFeeds,
}) {
  if (item.quantityAvailable <= 0) return 0;
  final type = item.feedType;
  if (type == null) return null;

  final cutoff = DateTime.now().subtract(const Duration(days: 14));
  final relevant = recentFeeds.where((r) {
    if (r.farmRef != item.farmRef) return false;
    if (r.feedType != type) return false;
    return !r.recordedDate.isBefore(cutoff);
  }).toList();

  if (relevant.isEmpty) return null;

  final total = relevant.fold<double>(0, (sum, r) => sum + r.amount);
  final daysSpan = relevant
      .map((r) => DateTime(r.recordedDate.year, r.recordedDate.month, r.recordedDate.day))
      .toSet()
      .length
      .clamp(1, 14);
  final avgPerDay = total / daysSpan;
  if (avgPerDay <= 0) return null;
  return (item.quantityAvailable / avgPerDay).floor().clamp(0, 9999);
}
