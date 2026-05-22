import '../../../core/error/api_result.dart';
import 'vaccine_dto.dart';

abstract class VaccineRepositoryContract {
  Future<VaccinePageResult?> readCachedList();

  Future<VaccineRemindersData?> readCachedReminders();

  Future<ApiResult<VaccinePageResult>> listRecords({
    String? animalId,
    VaccineStatus? status,
    int page,
    int limit,
    bool forceRefresh,
  });

  Future<ApiResult<VaccineRemindersData>> getReminders({bool forceRefresh});

  Future<ApiResult<VaccineRecord>> getRecord(String id);

  Future<ApiResult<VaccineRecord>> createRecord(VaccineInput input);

  Future<ApiResult<VaccineRecord>> updateRecord(String id, VaccineInput input);

  Future<ApiResult<void>> deleteRecord(String id);

  Future<void> saveDraft(VaccineInput input, {String? recordId});

  Future<VaccineInput?> readDraft({String? recordId});

  Future<void> clearDraft({String? recordId});
}
