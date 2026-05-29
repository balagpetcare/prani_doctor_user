import '../../../core/error/api_result.dart';
import 'phase4_feed_dto.dart';

abstract class Phase4FeedRepositoryContract {
  Future<Phase4FeedPageResult<Phase4FeedItem>?> readCachedFeedItems(
    String farmRef,
  );

  Future<Phase4FeedPageResult<Phase4FeedInventoryItem>?> readCachedInventory(
    String farmRef,
  );

  Future<ApiResult<Phase4FeedPageResult<Phase4FeedItem>>> listFeedItems({
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
    bool forceRefresh = false,
  });

  Future<ApiResult<Phase4FeedItem>> getFeedItem(
    String id, {
    bool forceRefresh = false,
  });

  Future<ApiResult<Phase4FeedPageResult<Phase4FeedInventoryItem>>>
  listInventory({
    required String farmRef,
    int page = 1,
    int limit = 20,
    String? search,
    bool forceRefresh = false,
  });

  Future<ApiResult<List<Phase4LowStockAlert>>> listLowStockAlerts(
    String farmRef,
  );

  Future<ApiResult<Phase4FeedInventoryItem>> recordPurchase(
    Phase4FeedPurchaseInput input,
  );

  Future<ApiResult<Phase4FeedConsumptionRecord>> recordConsumption(
    Phase4FeedConsumptionInput input,
  );

  Future<ApiResult<Phase4FeedPageResult<Phase4FeedConsumptionRecord>>>
  listConsumption({
    required String farmRef,
    int page = 1,
    int limit = 20,
    String? livestockId,
    bool forceRefresh = false,
  });

  Future<Phase4FeedPurchaseInput?> readPurchaseDraft();

  Future<void> savePurchaseDraft(Phase4FeedPurchaseInput input);

  Future<void> clearPurchaseDraft();

  Future<Phase4FeedConsumptionInput?> readConsumptionDraft();

  Future<void> saveConsumptionDraft(Phase4FeedConsumptionInput input);

  Future<void> clearConsumptionDraft();
}
