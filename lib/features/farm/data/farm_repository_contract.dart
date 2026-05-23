import '../../../core/error/api_result.dart';
import 'farm_dto.dart';

abstract class FarmRepositoryContract {
  Future<ApiResult<FarmPageResult>> listFarms({
    int page = 1,
    int pageSize = 20,
    String search = '',
    FarmFilter filter = FarmFilter.all,
    FarmSort sort = FarmSort.nameAsc,
    bool forceRefresh = false,
  });

  Future<ApiResult<FarmDetail>> getFarm(String id, {bool forceRefresh = false});

  Future<ApiResult<Farm>> saveFarm(FarmInput input, {String? farmId});

  Future<ApiResult<String>> uploadCoverImage(
    String filePath, {
    void Function(int sent, int total)? onProgress,
  });

  Future<FarmPageResult?> readCachedFarmList();

  Future<void> saveDraft(FarmInput input, {String? farmId});

  Future<FarmInput?> readDraft({String? farmId});

  Future<void> clearDraft({String? farmId});

  Future<String?> readActiveFarmId();

  Future<void> writeActiveFarmId(String? farmId);
}
