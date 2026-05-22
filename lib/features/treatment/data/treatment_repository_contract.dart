import '../../../core/error/api_result.dart';
import 'treatment_dto.dart';

abstract class TreatmentRepositoryContract {
  Future<TreatmentPageResult?> readCachedList();

  Future<ApiResult<TreatmentPageResult>> listRecords({
    String? animalId,
    TreatmentStatus? status,
    String search,
    int page,
    int limit,
    bool forceRefresh,
  });

  Future<ApiResult<FarmTreatment>> getRecord(String id);

  Future<ApiResult<FarmTreatment>> createRecord(TreatmentInput input);

  Future<ApiResult<FarmTreatment>> updateRecord(String id, TreatmentInput input);

  Future<ApiResult<void>> deleteRecord(String id);

  Future<void> saveDraft(TreatmentInput input, {String? recordId});

  Future<TreatmentInput?> readDraft({String? recordId});

  Future<void> clearDraft({String? recordId});
}
