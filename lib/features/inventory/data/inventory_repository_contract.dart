import '../../../core/error/api_result.dart';
import 'inventory_dto.dart';

abstract class InventoryRepositoryContract {
  Future<InventorySummary?> readCachedSummary(String farmRef);
  Future<InventoryListResult?> readCachedFeedList(String farmRef);
  Future<InventoryListResult?> readCachedMedicineList(String farmRef);

  Future<ApiResult<InventorySummary>> getSummary(
    String farmRef, {
    bool forceRefresh = false,
  });

  Future<ApiResult<InventoryListResult>> listFeed(
    String farmRef, {
    String search = '',
    int page = 1,
    int limit = 50,
    bool forceRefresh = false,
  });

  Future<ApiResult<InventoryListResult>> listMedicine(
    String farmRef, {
    String search = '',
    int page = 1,
    int limit = 50,
    bool forceRefresh = false,
  });

  Future<ApiResult<InventoryItem>> addStock(InventoryAddInput input);

  Future<ApiResult<List<InventoryItem>>> addFeedCatalogBatch(
    InventoryAddBatchInput input,
  );

  Future<ApiResult<InventoryItem>> consumeStock(InventoryConsumeInput input);
}
