import '../../../core/error/api_result.dart';
import 'fattening_batch_dto.dart';
import 'fattening_feed_dto.dart';
import 'fattening_qurbani_dto.dart';
import 'fattening_roi_dto.dart';
import '../weight/data/weight_dto.dart';

abstract interface class FatteningRepositoryContract {
  Future<FatteningBatchPageResult?> readCachedList(String farmId);

  Future<FatteningBatchDetail?> readCachedDetail(String batchId);

  Future<ApiResult<FatteningBatchPageResult>> listBatches({
    required String farmId,
    FatteningBatchStatus? status,
    int page = 1,
    bool forceRefresh = false,
  });

  Future<ApiResult<FatteningBatchDetail>> getBatch(
    String batchId, {
    bool forceRefresh = false,
  });

  Future<ApiResult<FatteningBatch>> createBatch(FatteningBatchInput input);

  Future<ApiResult<FatteningBatchDetail>> addAnimals(
    String batchId,
    List<String> animalIds,
  );

  Future<ApiResult<FatteningBatchDetail>> startBatch(
    String batchId, {
    DateTime? startDate,
  });

  Future<WeightHistoryResult?> readCachedWeightHistory(String batchId);

  Future<ApiResult<WeightHistoryResult>> getWeightHistory({
    required String batchId,
    String? animalId,
    bool forceRefresh = false,
  });

  Future<ApiResult<WeightRecord>> createWeightRecord(WeightRecordInput input);

  Future<BatchWeightProgress?> readCachedBatchProgress(String batchId);

  Future<ApiResult<BatchWeightProgress>> getBatchProgress(String batchId);

  Future<BatchFeedDashboard?> readCachedFeedDashboard(String batchId);

  Future<ApiResult<BatchFeedDashboard>> getFeedDashboard(String batchId);

  Future<ApiResult<BatchFeedPlan>> upsertFeedPlan(
    String batchId,
    BatchFeedPlan plan,
  );

  Future<FatteningBatchRoi?> readCachedRoi(String batchId);

  Future<ApiResult<FatteningBatchRoi>> getRoi(String batchId);

  Future<ApiResult<FatteningBatchRoi>> upsertRoi(
    String batchId,
    FatteningRoiSettings settings,
  );

  Future<QurbaniDashboard?> readCachedQurbani(String batchId);

  Future<ApiResult<QurbaniDashboard>> getQurbaniDashboard(String batchId);
}
