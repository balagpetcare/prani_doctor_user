import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_result.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_helpers.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/offline/local_cache_contract.dart';
import '../../../core/offline/network_errors.dart';
import '../../home/data/dashboard_context_dto.dart';
import '../../shared/upload/services/upload_service.dart';
import '../../offline/data/local_cache_service.dart';
import '../../offline/offline_providers.dart';
import '../../profile/data/mobile_me_dto.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/data/profile_repository_contract.dart';
import 'farm_api_paths.dart';
import 'farm_dto.dart';
import 'farm_repository_contract.dart';

/// Customer farm — composite over profile location + dashboard farmSummary + animals.
class FarmRepository implements FarmRepositoryContract {
  FarmRepository(this._dio, this._cache, this._profileRepo, this._uploads);

  final Dio _dio;
  final LocalCacheService _cache;
  final ProfileRepositoryContract _profileRepo;
  final UploadService _uploads;

  Future<ApiResult<FarmPageResult>>? _listInFlight;

  static const _maxAttempts = 2;

  @override
  Future<FarmPageResult?> readCachedFarmList() async {
    final cached = await _cache.read(LocalCacheContract.farmsListKey);
    if (cached == null) return null;
    final farms = (cached['farms'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Farm.fromJson)
        .toList();
    return FarmPageResult(
      farms: farms,
      total: cached['total'] as int? ?? farms.length,
      page: cached['page'] as int? ?? 1,
      pageSize: cached['pageSize'] as int? ?? 20,
      hasMore: cached['hasMore'] as bool? ?? false,
      fromCache: true,
    );
  }

  Future<void> _writeListCache(FarmPageResult page) async {
    await _cache.write(LocalCacheContract.farmsListKey, {
      'farms': page.farms.map((f) => f.toJson()).toList(),
      'total': page.total,
      'page': page.page,
      'pageSize': page.pageSize,
      'hasMore': page.hasMore,
    }, LocalCacheContract.dashboardTtl);
  }

  Future<void> _writeDetailCache(FarmDetail detail) async {
    await _cache.write(
      LocalCacheContract.farmDetailKey(detail.farm.id),
      {
        'farm': detail.farm.toJson(),
        'animals': detail.animals
            .map(
              (a) => {
                'id': a.id,
                'name': a.name,
                'animalType': a.animalType,
                if (a.photoUrl != null) 'photoUrl': a.photoUrl,
              },
            )
            .toList(),
      },
      LocalCacheContract.dashboardTtl,
    );
  }

  Future<({MobileMeDto profile, FarmSummary? summary})> _loadSources() async {
    MobileMeDto? profile;
    FarmSummary? summary;

    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        final meResult = await _profileRepo.getMe(forceRefresh: attempt > 1);
        profile = meResult.when(success: (p) => p, failure: (_) => null);

        final dashData = await getJson(_dio, FarmApiPaths.dashboardContext);
        final ctx = DashboardContext.fromJson(dashData);
        summary = ctx.farmSummary;
        if (profile != null) break;
      } on AppException catch (e) {
        if (!isTransientNetworkError(e) || attempt >= _maxAttempts) break;
      }
    }

    if (profile == null) {
      final meResult = await _profileRepo.getMe();
      profile = meResult.when(success: (p) => p, failure: (_) => null);
    }

    if (profile == null) {
      throw const AppException(message: 'Could not load profile');
    }

    return (profile: profile, summary: summary);
  }

  List<Farm> _applyFilters(
    List<Farm> farms,
    String search,
    FarmFilter filter,
    FarmSort sort,
  ) {
    var result = farms;
    if (search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      result = result
          .where(
            (f) =>
                f.name.toLowerCase().contains(q) ||
                f.locationLabel.toLowerCase().contains(q),
          )
          .toList();
    }
    switch (filter) {
      case FarmFilter.all:
        break;
      case FarmFilter.hasAnimals:
        result = result.where((f) => f.animalCount > 0).toList();
      case FarmFilter.needsLocation:
        result = result.where((f) => !f.hasLocation).toList();
    }
    result = [...result];
    switch (sort) {
      case FarmSort.nameAsc:
        result.sort((a, b) => a.name.compareTo(b.name));
      case FarmSort.nameDesc:
        result.sort((a, b) => b.name.compareTo(a.name));
      case FarmSort.animalsDesc:
        result.sort((a, b) => b.animalCount.compareTo(a.animalCount));
    }
    return result;
  }

  FarmPageResult _paginate(List<Farm> farms, int page, int pageSize) {
    final start = (page - 1) * pageSize;
    if (start >= farms.length) {
      return FarmPageResult(
        farms: const [],
        total: farms.length,
        page: page,
        pageSize: pageSize,
        hasMore: false,
      );
    }
    final end = (start + pageSize).clamp(0, farms.length);
    final slice = farms.sublist(start, end);
    return FarmPageResult(
      farms: slice,
      total: farms.length,
      page: page,
      pageSize: pageSize,
      hasMore: end < farms.length,
    );
  }

  @override
  Future<ApiResult<FarmPageResult>> listFarms({
    int page = 1,
    int pageSize = 20,
    String search = '',
    FarmFilter filter = FarmFilter.all,
    FarmSort sort = FarmSort.nameAsc,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _listInFlight != null) {
      return _listInFlight!;
    }

    final future = _fetchList(
      page: page,
      pageSize: pageSize,
      search: search,
      filter: filter,
      sort: sort,
    );
    _listInFlight = future;
    try {
      return await future;
    } finally {
      _listInFlight = null;
    }
  }

  Future<ApiResult<FarmPageResult>> _fetchList({
    required int page,
    required int pageSize,
    required String search,
    required FarmFilter filter,
    required FarmSort sort,
  }) async {
    try {
      final sources = await _loadSources();
      final farm = Farm.fromProfile(
        profile: sources.profile,
        animalCount: sources.summary?.animalCount ?? 0,
        activeAnimalCount: sources.summary?.activeAnimalCount ?? 0,
        villageLabel: sources.summary?.primaryVillageLabelBn,
      );
      final all = farm == null ? <Farm>[] : [farm];
      final filtered = _applyFilters(all, search, filter, sort);
      final pageResult = _paginate(filtered, page, pageSize);
      await _writeListCache(pageResult);
      if (farm != null) {
        await writeActiveFarmId(farm.id);
      }
      return ApiResult.success(pageResult);
    } on AppException catch (e) {
      final cached = await readCachedFarmList();
      if (cached != null) {
        final filtered = _applyFilters(cached.farms, search, filter, sort);
        return ApiResult.success(
          _paginate(filtered, page, pageSize).copyWith(fromCache: true),
        );
      }
      return ApiResult.failure(e);
    } catch (e) {
      final cached = await readCachedFarmList();
      if (cached != null) {
        final filtered = _applyFilters(cached.farms, search, filter, sort);
        return ApiResult.success(
          _paginate(filtered, page, pageSize).copyWith(fromCache: true),
        );
      }
      return ApiResult.failure(
        AppException(message: 'Could not load farms', cause: e),
      );
    }
  }

  @override
  Future<ApiResult<FarmDetail>> getFarm(
    String id, {
    bool forceRefresh = false,
  }) async {
    try {
      final sources = await _loadSources();
      final farm = Farm.fromProfile(
        profile: sources.profile,
        animalCount: sources.summary?.animalCount ?? 0,
        activeAnimalCount: sources.summary?.activeAnimalCount ?? 0,
        villageLabel: sources.summary?.primaryVillageLabelBn,
      );
      if (farm == null || farm.id != id) {
        return const ApiResult.failure(AppException(message: 'Farm not found'));
      }

      final animals = await _loadAnimals();
      final detail = FarmDetail(farm: farm, animals: animals);
      await _writeDetailCache(detail);
      return ApiResult.success(detail);
    } on AppException catch (e) {
      final cached = await _cache.read(LocalCacheContract.farmDetailKey(id));
      if (cached != null) {
        final farm = Farm.fromJson(cached['farm'] as Map<String, dynamic>);
        final animals = (cached['animals'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(FarmAnimalSummary.fromJson)
            .toList();
        return ApiResult.success(
          FarmDetail(farm: farm, animals: animals, fromCache: true),
        );
      }
      return ApiResult.failure(e);
    } catch (e) {
      return ApiResult.failure(
        AppException(message: 'Could not load farm', cause: e),
      );
    }
  }

  Future<List<FarmAnimalSummary>> _loadAnimals() async {
    try {
      final data = await getJson(_dio, FarmApiPaths.animals);
      return (data['animals'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(FarmAnimalSummary.fromJson)
          .toList();
    } on AppException {
      return const [];
    }
  }

  @override
  Future<ApiResult<Farm>> saveFarm(FarmInput input, {String? farmId}) async {
    final patch = input.toPatchInput();
    final result = await _profileRepo.patchMe(patch);
    if (result case ApiSuccess(:final data)) {
      FarmSummary? summary;
      try {
        final dashData = await getJson(_dio, FarmApiPaths.dashboardContext);
        summary = DashboardContext.fromJson(dashData).farmSummary;
      } on AppException {
        summary = null;
      }
      final farm = Farm.fromProfile(
        profile: data,
        animalCount: summary?.animalCount ?? 0,
        activeAnimalCount: summary?.activeAnimalCount ?? 0,
        villageLabel: summary?.primaryVillageLabelBn ?? input.areaLabel,
      );
      if (farm == null) {
        return const ApiResult.failure(
          AppException(message: 'Farm location required'),
        );
      }
      await writeActiveFarmId(farm.id);
      await _writeListCache(
        FarmPageResult(
          farms: [farm],
          total: 1,
          page: 1,
          pageSize: 20,
          hasMore: false,
        ),
      );
      return ApiResult.success(farm);
    }
    if (result case ApiFailure(:final error)) {
      if (error.code == offlineQueuedCode && error.cause is MobileMeDto) {
        final profile = error.cause as MobileMeDto;
        final farm = Farm.fromProfile(
          profile: profile,
          villageLabel: input.areaLabel,
        );
        if (farm != null) {
          return ApiResult.success(farm.copyWith(fromCache: true));
        }
      }
      return ApiResult.failure(error);
    }
    return const ApiResult.failure(
      AppException(message: 'Could not save farm'),
    );
  }

  @override
  Future<ApiResult<String>> uploadCoverImage(
    String filePath, {
    void Function(int sent, int total)? onProgress,
  }) async {
    final result = await _uploads.uploadCoverImage(
      filePath,
      onProgress: onProgress,
    );
    return result.when(
      success: (upload) {
        final url = upload.coverPhotoUrl ?? upload.url;
        if (url.isEmpty) {
          return const ApiResult.failure(
            AppException(
              message: 'Upload succeeded but no image URL returned',
            ),
          );
        }
        return ApiResult.success(url);
      },
      failure: ApiResult.failure,
    );
  }

  @override
  Future<void> saveDraft(FarmInput input, {String? farmId}) async {
    final key = farmId == null
        ? LocalCacheContract.farmDraftKey
        : LocalCacheContract.farmEditDraftKey(farmId);
    await _cache.write(
      key,
      input.toDraftJson(),
      LocalCacheContract.caseDraftTtl,
    );
  }

  @override
  Future<FarmInput?> readDraft({String? farmId}) async {
    final key = farmId == null
        ? LocalCacheContract.farmDraftKey
        : LocalCacheContract.farmEditDraftKey(farmId);
    final cached = await _cache.read(key);
    if (cached == null) return null;
    return FarmInput.fromDraftJson(cached);
  }

  @override
  Future<void> clearDraft({String? farmId}) async {
    final key = farmId == null
        ? LocalCacheContract.farmDraftKey
        : LocalCacheContract.farmEditDraftKey(farmId);
    await _cache.write(key, {}, Duration.zero);
  }

  @override
  Future<String?> readActiveFarmId() async {
    final cached = await _cache.read(LocalCacheContract.activeFarmIdKey);
    final id = cached?['id'] as String?;
    return id != null && id.isNotEmpty ? id : null;
  }

  @override
  Future<void> writeActiveFarmId(String? farmId) async {
    if (farmId == null || farmId.isEmpty) {
      await _cache.write(LocalCacheContract.activeFarmIdKey, {}, Duration.zero);
      return;
    }
    await _cache.write(LocalCacheContract.activeFarmIdKey, {
      'id': farmId,
    }, LocalCacheContract.dashboardTtl);
  }
}

extension on FarmPageResult {
  FarmPageResult copyWith({bool? fromCache}) {
    return FarmPageResult(
      farms: farms,
      total: total,
      page: page,
      pageSize: pageSize,
      hasMore: hasMore,
      fromCache: fromCache ?? this.fromCache,
    );
  }
}

final farmRepositoryProvider = Provider<FarmRepositoryContract>((ref) {
  return FarmRepository(
    ref.watch(dioProvider),
    ref.watch(localCacheServiceProvider),
    ref.watch(profileRepositoryProvider),
    ref.watch(uploadServiceProvider),
  );
});
