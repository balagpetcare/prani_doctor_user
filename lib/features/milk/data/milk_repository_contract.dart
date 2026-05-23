import '../../../core/error/api_result.dart';
import 'milk_dto.dart';

abstract class MilkRepositoryContract {
  Future<MilkPageResult?> readCachedList();

  Future<MilkSummary?> readCachedSummary(DateTime date);

  Future<MilkChartsData?> readCachedCharts();

  Future<ApiResult<MilkPageResult>> listRecords({
    DateTime? from,
    DateTime? to,
    String? animalId,
    int page,
    int limit,
    bool forceRefresh,
  });

  Future<ApiResult<MilkRecord>> getRecord(String id);

  Future<ApiResult<MilkRecord>> createRecord(MilkInput input);

  Future<ApiResult<MilkRecord>> updateRecord(String id, MilkInput input);

  Future<ApiResult<void>> deleteRecord(String id);

  Future<ApiResult<MilkSummary>> getSummary({
    DateTime? date,
    DateTime? from,
    DateTime? to,
  });

  Future<ApiResult<MilkChartsData>> getCharts({DateTime? from, DateTime? to});

  Future<void> saveDraft(MilkInput input, {String? recordId});

  Future<MilkInput?> readDraft({String? recordId});

  Future<void> clearDraft({String? recordId});
}
