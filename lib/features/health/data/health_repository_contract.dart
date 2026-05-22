import '../../../core/error/api_result.dart';
import 'health_dto.dart';

abstract class HealthRepositoryContract {
  Future<HealthPageResult?> readCachedList();

  Future<HealthTimelineResult?> readCachedTimeline();

  Future<ApiResult<HealthPageResult>> listRecords({
    DateTime? from,
    DateTime? to,
    String? animalId,
    HealthEventType? eventType,
    String search,
    int page,
    int limit,
    bool forceRefresh,
  });

  Future<ApiResult<HealthTimelineResult>> getTimeline({
    DateTime? from,
    DateTime? to,
    String? animalId,
    HealthEventType? eventType,
    String search,
    int page,
    int limit,
    bool forceRefresh,
  });

  Future<ApiResult<HealthEvent>> getRecord(String id);

  Future<ApiResult<HealthEvent>> createRecord(HealthInput input);

  Future<ApiResult<HealthEvent>> updateRecord(String id, HealthInput input);

  Future<ApiResult<void>> deleteRecord(String id);

  Future<void> saveDraft(HealthInput input, {String? recordId});

  Future<HealthInput?> readDraft({String? recordId});

  Future<void> clearDraft({String? recordId});
}
