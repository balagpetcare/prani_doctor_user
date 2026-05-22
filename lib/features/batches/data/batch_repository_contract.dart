import '../../../core/error/api_result.dart';
import 'batch_dto.dart';

abstract class BatchRepositoryContract {
  Future<BatchPageResult?> readCachedList();

  Future<ApiResult<BatchPageResult>> listBatches({
    int page,
    int pageSize,
    String search,
    BatchFilter filter,
    bool forceRefresh,
  });

  Future<ApiResult<BatchDetail>> getBatch(String id, {bool forceRefresh});

  Future<ApiResult<AnimalBatch>> createBatch(BatchInput input);

  Future<ApiResult<AnimalBatch>> updateBatch(String id, BatchInput input);

  Future<ApiResult<AnimalBatch>> moveAnimals(BatchMoveInput input);

  Future<ApiResult<AnimalBatch>> mergeBatches(BatchMergeInput input);

  Future<void> saveDraft(BatchInput input, {String? batchId});

  Future<BatchInput?> readDraft({String? batchId});

  Future<void> clearDraft({String? batchId});
}
