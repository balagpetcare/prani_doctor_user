import '../../../core/error/api_result.dart';
import 'feed_dto.dart';

abstract class FeedRepositoryContract {
  Future<FeedPageResult?> readCachedList();

  Future<FeedCostData?> readCachedCost();

  Future<FeedAnalyticsData?> readCachedAnalytics();

  Future<ApiResult<FeedPageResult>> listRecords({
    DateTime? from,
    DateTime? to,
    String? animalId,
    String? batchId,
    FeedType? feedType,
    String search,
    int page,
    int limit,
    bool forceRefresh,
  });

  Future<ApiResult<FeedRecord>> getRecord(String id);

  Future<ApiResult<FeedRecord>> createRecord(FeedInput input);

  Future<ApiResult<FeedRecord>> updateRecord(String id, FeedInput input);

  Future<ApiResult<void>> deleteRecord(String id);

  Future<ApiResult<FeedCostData>> getCost({DateTime? from, DateTime? to});

  Future<ApiResult<FeedAnalyticsData>> getAnalytics({
    DateTime? from,
    DateTime? to,
  });

  Future<void> saveDraft(FeedInput input, {String? recordId});

  Future<FeedInput?> readDraft({String? recordId});

  Future<void> clearDraft({String? recordId});
}
