import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_result.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_helpers.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/offline/local_cache_contract.dart';
import '../../../core/offline/network_errors.dart';
import '../../offline/data/local_cache_service.dart';
import '../../offline/data/outbox_item.dart';
import '../../offline/data/outbox_service.dart';
import '../../offline/offline_providers.dart';
import '../../shared/upload/services/upload_service.dart';
import 'livestock_api_paths.dart';
import 'livestock_dto.dart';
import 'livestock_repository_contract.dart';

class LivestockRepository implements LivestockRepositoryContract {
  LivestockRepository(this._dio, this._cache, this._outbox, this._uploads);

  final Dio _dio;
  final LocalCacheService _cache;
  final OutboxService _outbox;
  final UploadService _uploads;

  String _listKey(String farmRef) => LocalCacheContract.livestockListKey(farmRef);

  @override
  Future<LivestockPageResult?> readCachedList(String farmRef) async {
    final cached = await _cache.read(_listKey(farmRef));
    if (cached == null) return null;
    final items = (cached['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((j) => LivestockProfile.fromJson(j, fromCache: true))
        .toList();
    return LivestockPageResult(
      items: items,
      page: cached['page'] as int? ?? 1,
      pageSize: cached['pageSize'] as int? ?? 20,
      total: cached['total'] as int? ?? items.length,
      hasMore: cached['hasMore'] as bool? ?? false,
      fromCache: true,
    );
  }

  @override
  Future<LivestockProfile?> readCachedDetail(String id) async {
    final cached = await _cache.read(LocalCacheContract.livestockDetailKey(id));
    if (cached == null) return null;
    final raw = cached['livestock'];
    if (raw is! Map<String, dynamic>) return null;
    return LivestockProfile.fromJson(raw, fromCache: true);
  }

  Future<void> _writeListCache(String farmRef, LivestockPageResult page) async {
    await _cache.write(_listKey(farmRef), {
      'items': page.items.map((e) => e.toJson()).toList(),
      'page': page.page,
      'pageSize': page.pageSize,
      'total': page.total,
      'hasMore': page.hasMore,
    }, LocalCacheContract.dataTtl);
  }

  Future<void> _writeDetailCache(LivestockProfile profile) async {
    await _cache.write(
      LocalCacheContract.livestockDetailKey(profile.id),
      {'livestock': profile.toJson()},
      LocalCacheContract.dataTtl,
    );
  }

  @override
  Future<ApiResult<LivestockPageResult>> listLivestock({
    required String farmRef,
    int page = 1,
    int limit = 20,
    String? search,
    LivestockFilter filter = LivestockFilter.all,
    LivestockSort sort = LivestockSort.recentFirst,
    bool forceRefresh = false,
  }) async {
    try {
      final query = <String, dynamic>{
        'farmRef': farmRef,
        'page': page,
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (filter == LivestockFilter.active) 'lifecycleStatus': 'ACTIVE',
        if (filter == LivestockFilter.inactive) 'lifecycleStatus': 'INACTIVE',
        'sortBy': sort == LivestockSort.nameAsc ? 'name' : 'createdAt',
        'sortOrder': sort == LivestockSort.nameAsc ? 'asc' : 'desc',
      };
      final data = await getJson(_dio, LivestockApiPaths.list, queryParameters: query);
      final itemsRaw = data['items'] as List<dynamic>? ?? const [];
      final result = LivestockPageResult(
        items: itemsRaw
            .whereType<Map<String, dynamic>>()
            .map((j) => LivestockProfile.fromJson(j))
            .toList(),
        page: data['page'] as int? ?? page,
        pageSize: data['limit'] as int? ?? limit,
        total: data['total'] as int? ?? itemsRaw.length,
        hasMore: data['hasMore'] as bool? ?? false,
      );
      if (page == 1) await _writeListCache(farmRef, result);
      return ApiResult.success(result);
    } on AppException catch (e) {
      if (!forceRefresh) {
        final cached = await readCachedList(farmRef);
        if (cached != null) return ApiResult.success(cached);
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<LivestockProfile>> getLivestock(
    String id, {
    bool forceRefresh = false,
  }) async {
    try {
      final data = await getJson(_dio, LivestockApiPaths.detail(id));
      final raw = data['livestock'] as Map<String, dynamic>? ?? data;
      final profile = LivestockProfile.fromJson(raw);
      await _writeDetailCache(profile);
      return ApiResult.success(profile);
    } on AppException catch (e) {
      if (!forceRefresh) {
        final cached = await readCachedDetail(id);
        if (cached != null) return ApiResult.success(cached);
      }
      return ApiResult.failure(e);
    }
  }

  Future<void> _enqueueCreate(Map<String, dynamic> body) async {
    final sequence = (await _outbox.listAll()).length + 1;
    await _outbox.enqueue(
      OutboxItem(
        idempotencyKey:
            'livestock-create-$sequence-${DateTime.now().millisecondsSinceEpoch}',
        kind: OutboxKind.livestockCreate,
        payload: body,
        clientSequence: sequence,
        attemptCount: 0,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  @override
  Future<ApiResult<LivestockProfile>> createLivestock(
    LivestockInput input,
  ) async {
    final body = input.toJson();
    try {
      final data = await postJson(_dio, LivestockApiPaths.list, body);
      final raw = data['livestock'] as Map<String, dynamic>? ?? data;
      final profile = LivestockProfile.fromJson(raw);
      await _writeDetailCache(profile);
      await clearDraft();
      return ApiResult.success(profile);
    } on AppException catch (e) {
      if (isTransientNetworkError(e)) {
        await _enqueueCreate(body);
        return const ApiResult.failure(
          AppException(
            message: 'Saved offline — will sync when online',
            code: offlineQueuedCode,
          ),
        );
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<LivestockProfile>> updateLivestock(
    String id,
    LivestockInput input,
  ) async {
    try {
      final data = await patchJson(
        _dio,
        LivestockApiPaths.detail(id),
        input.toJson(),
      );
      final raw = data['livestock'] as Map<String, dynamic>? ?? data;
      final profile = LivestockProfile.fromJson(raw);
      await _writeDetailCache(profile);
      await clearDraft(livestockId: id);
      return ApiResult.success(profile);
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<LivestockProfile>> addImage(
    String id, {
    required String url,
    String? caption,
  }) async {
    try {
      await postJson(_dio, LivestockApiPaths.images(id), {
        'url': url,
        if (caption != null && caption.trim().isNotEmpty) 'caption': caption.trim(),
      });
      return getLivestock(id, forceRefresh: true);
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<String>> uploadPhoto(
    String localPath, {
    void Function(int sent, int total)? onProgress,
  }) async {
    final result = await _uploads.uploadAnimalPhoto(
      localPath,
      onProgress: onProgress,
    );
    return result.when(
      success: (upload) {
        final url = upload.animalPhotoUrl;
        if (url.isEmpty) {
          return const ApiResult.failure(
            AppException(message: 'Upload succeeded but no URL returned'),
          );
        }
        return ApiResult.success(url);
      },
      failure: ApiResult.failure,
    );
  }

  @override
  Future<ApiResult<List<LivestockTimelineItem>>> loadTimeline(String id) async {
    try {
      final health = await getJson(
        _dio,
        LivestockApiPaths.healthRecords(id),
        queryParameters: {'limit': 50},
      );
      final vaccines = await getJson(
        _dio,
        LivestockApiPaths.vaccinations(id),
        queryParameters: {'limit': 50},
      );
      final items = <LivestockTimelineItem>[];
      for (final raw in (health['items'] as List<dynamic>? ?? const [])) {
        if (raw is! Map<String, dynamic>) continue;
        final record = LivestockHealthRecord.fromJson(raw);
        items.add(
          LivestockTimelineItem(
            id: record.id,
            type: 'health',
            title: record.title,
            subtitle: record.diagnosis ?? record.recordType,
            occurredAt: record.recordedDate,
          ),
        );
      }
      for (final raw in (vaccines['items'] as List<dynamic>? ?? const [])) {
        if (raw is! Map<String, dynamic>) continue;
        final record = LivestockVaccinationRecord.fromJson(raw);
        items.add(
          LivestockTimelineItem(
            id: record.id,
            type: 'vaccine',
            title: record.vaccineName,
            subtitle: record.status,
            occurredAt: record.scheduledDate,
          ),
        );
      }
      items.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      await _cache.write(
        LocalCacheContract.livestockTimelineKey(id),
        {'items': items.map((e) => {
          'id': e.id,
          'type': e.type,
          'title': e.title,
          'subtitle': e.subtitle,
          'occurredAt': e.occurredAt,
        }).toList()},
        LocalCacheContract.dataTtl,
      );
      return ApiResult.success(items);
    } on AppException catch (e) {
      final cached = await _cache.read(LocalCacheContract.livestockTimelineKey(id));
      if (cached != null) {
        final items = (cached['items'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(
              (j) => LivestockTimelineItem(
                id: j['id'] as String,
                type: j['type'] as String,
                title: j['title'] as String,
                subtitle: j['subtitle'] as String,
                occurredAt: j['occurredAt'] as String,
              ),
            )
            .toList();
        return ApiResult.success(items);
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<LivestockInput?> readDraft({String? livestockId}) async {
    final key = livestockId == null
        ? LocalCacheContract.livestockDraftKey
        : LocalCacheContract.livestockEditDraftKey(livestockId);
    final cached = await _cache.read(key);
    if (cached == null) return null;
    return LivestockInput.fromJson(cached);
  }

  @override
  Future<void> saveDraft(LivestockInput input, {String? livestockId}) async {
    final key = livestockId == null
        ? LocalCacheContract.livestockDraftKey
        : LocalCacheContract.livestockEditDraftKey(livestockId);
    await _cache.write(key, input.toJson(), LocalCacheContract.profileTtl);
  }

  @override
  Future<void> clearDraft({String? livestockId}) async {
    final key = livestockId == null
        ? LocalCacheContract.livestockDraftKey
        : LocalCacheContract.livestockEditDraftKey(livestockId);
    await _cache.write(key, {}, Duration.zero);
  }
}

final livestockRepositoryProvider = Provider<LivestockRepository>((ref) {
  return LivestockRepository(
    ref.watch(dioProvider),
    ref.watch(localCacheServiceProvider),
    ref.watch(outboxServiceProvider),
    ref.watch(uploadServiceProvider),
  );
});
