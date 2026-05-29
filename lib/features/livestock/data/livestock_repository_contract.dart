import '../../../core/error/api_result.dart';
import 'livestock_dto.dart';

abstract class LivestockRepositoryContract {
  Future<LivestockPageResult?> readCachedList(String farmRef);

  Future<LivestockProfile?> readCachedDetail(String id);

  Future<ApiResult<LivestockPageResult>> listLivestock({
    required String farmRef,
    int page = 1,
    int limit = 20,
    String? search,
    LivestockFilter filter = LivestockFilter.all,
    LivestockSort sort = LivestockSort.recentFirst,
    bool forceRefresh = false,
  });

  Future<ApiResult<LivestockProfile>> getLivestock(
    String id, {
    bool forceRefresh = false,
  });

  Future<ApiResult<LivestockProfile>> createLivestock(LivestockInput input);

  Future<ApiResult<LivestockProfile>> updateLivestock(
    String id,
    LivestockInput input,
  );

  Future<ApiResult<LivestockProfile>> addImage(
    String id, {
    required String url,
    String? caption,
  });

  Future<ApiResult<List<LivestockTimelineItem>>> loadTimeline(String id);

  Future<LivestockInput?> readDraft({String? livestockId});

  Future<void> saveDraft(LivestockInput input, {String? livestockId});

  Future<void> clearDraft({String? livestockId});
}
