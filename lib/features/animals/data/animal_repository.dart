import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_result.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/dio_helpers.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/offline/local_cache_contract.dart';
import '../../../core/offline/network_errors.dart';
import '../../offline/data/local_cache_service.dart';
import '../../offline/data/outbox_item.dart';
import '../../offline/data/outbox_service.dart';
import '../../offline/offline_providers.dart';
import '../../service_requests/data/service_request_repository.dart';
import 'animal_api_paths.dart';
import 'animal_dto.dart';
import 'animal_repository_contract.dart';

class AnimalRepository implements AnimalRepositoryContract {
  AnimalRepository(
    this._dio,
    this._cache,
    this._outbox,
    this._serviceRequests,
  );

  final Dio _dio;
  final LocalCacheService _cache;
  final OutboxService _outbox;
  final ServiceRequestRepository _serviceRequests;

  Future<ApiResult<AnimalPageResult>>? _listInFlight;

  @override
  Future<AnimalPageResult?> readCachedList() async {
    final cached = await _cache.read(LocalCacheContract.animalsListKey);
    if (cached == null) return null;
    final animals = (cached['animals'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((j) => AnimalProfile.fromJson(j, fromCache: true))
        .toList();
    return AnimalPageResult(
      animals: animals,
      total: cached['total'] as int? ?? animals.length,
      page: cached['page'] as int? ?? 1,
      pageSize: cached['pageSize'] as int? ?? 20,
      hasMore: cached['hasMore'] as bool? ?? false,
      fromCache: true,
    );
  }

  Future<void> _writeListCache(AnimalPageResult page) async {
    await _cache.write(
      LocalCacheContract.animalsListKey,
      {
        'animals': page.animals.map((a) => a.toJson()).toList(),
        'total': page.total,
        'page': page.page,
        'pageSize': page.pageSize,
        'hasMore': page.hasMore,
      },
      LocalCacheContract.profileTtl,
    );
  }

  List<AnimalProfile> _applyFilters(
    List<AnimalProfile> animals,
    String search,
    AnimalFilter filter,
  ) {
    var result = animals;
    if (search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      result = result.where((a) {
        return a.name.toLowerCase().contains(q) ||
            a.species.toLowerCase().contains(q) ||
            (a.microchipOrTag ?? '').toLowerCase().contains(q) ||
            (a.breed ?? '').toLowerCase().contains(q);
      }).toList();
    }
    switch (filter) {
      case AnimalFilter.all:
        break;
      case AnimalFilter.active:
        result = result.where((a) => a.active).toList();
      case AnimalFilter.inactive:
        result = result.where((a) => !a.active).toList();
      case AnimalFilter.livestock:
        result = result.where((a) => a.category == 'LIVESTOCK').toList();
      case AnimalFilter.pets:
        result = result.where((a) => a.category == 'PET').toList();
    }
    return result;
  }

  AnimalPageResult _paginate(List<AnimalProfile> animals, int page, int pageSize) {
    final start = (page - 1) * pageSize;
    if (start >= animals.length) {
      return AnimalPageResult(
        animals: const [],
        total: animals.length,
        page: page,
        pageSize: pageSize,
        hasMore: false,
      );
    }
    final end = (start + pageSize).clamp(0, animals.length);
    return AnimalPageResult(
      animals: animals.sublist(start, end),
      total: animals.length,
      page: page,
      pageSize: pageSize,
      hasMore: end < animals.length,
    );
  }

  Future<List<AnimalProfile>> _fetchAll({required bool includeInactive}) async {
    final data = await getJson(
      _dio,
      AnimalApiPaths.animals,
      queryParameters: includeInactive ? {'includeInactive': 'true'} : null,
    );
    return (data['animals'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(AnimalProfile.fromJson)
        .toList();
  }

  @override
  Future<ApiResult<AnimalPageResult>> listAnimals({
    int page = 1,
    int pageSize = 20,
    String search = '',
    AnimalFilter filter = AnimalFilter.all,
    bool includeInactive = false,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _listInFlight != null) {
      return _listInFlight!;
    }
    final future = _loadList(
      page: page,
      pageSize: pageSize,
      search: search,
      filter: filter,
      includeInactive: includeInactive || filter == AnimalFilter.inactive,
    );
    _listInFlight = future;
    try {
      return await future;
    } finally {
      _listInFlight = null;
    }
  }

  Future<ApiResult<AnimalPageResult>> _loadList({
    required int page,
    required int pageSize,
    required String search,
    required AnimalFilter filter,
    required bool includeInactive,
  }) async {
    try {
      final all = await _fetchAll(includeInactive: includeInactive);
      await _writeListCache(
        AnimalPageResult(
          animals: all,
          total: all.length,
          page: 1,
          pageSize: pageSize,
          hasMore: all.length > pageSize,
        ),
      );
      final filtered = _applyFilters(all, search, filter);
      return ApiResult.success(_paginate(filtered, page, pageSize));
    } on AppException catch (e) {
      final cached = await readCachedList();
      if (cached != null) {
        final filtered = _applyFilters(cached.animals, search, filter);
        return ApiResult.success(_paginate(filtered, page, pageSize).copyWith(fromCache: true));
      }
      return ApiResult.failure(e);
    } catch (e) {
      final cached = await readCachedList();
      if (cached != null) {
        final filtered = _applyFilters(cached.animals, search, filter);
        return ApiResult.success(_paginate(filtered, page, pageSize).copyWith(fromCache: true));
      }
      return ApiResult.failure(AppException(message: 'Could not load animals', cause: e));
    }
  }

  @override
  Future<ApiResult<AnimalDetail>> getAnimal(String id, {bool forceRefresh = false}) async {
    try {
      final data = await getJson(_dio, AnimalApiPaths.animal(id));
      final raw = data['animal'];
      if (raw is! Map<String, dynamic>) {
        return ApiResult.failure(const AppException(message: 'Animal not found'));
      }
      final animal = AnimalProfile.fromJson(raw);
      final detail = await _buildDetail(animal);
      await _cache.write(
        LocalCacheContract.animalDetailKey(id),
        {
          'animal': animal.toJson(),
          'timeline': detail.timeline
              .map((e) => {'title': e.title, 'subtitle': e.subtitle, 'at': e.at.toIso8601String()})
              .toList(),
          'history': detail.history
              .map((h) => {'id': h.id, 'title': h.title, 'status': h.status, 'at': h.at?.toIso8601String()})
              .toList(),
        },
        LocalCacheContract.profileTtl,
      );
      return ApiResult.success(detail);
    } on AppException catch (e) {
      final cached = await _cache.read(LocalCacheContract.animalDetailKey(id));
      if (cached != null) {
        return ApiResult.success(_detailFromCache(cached));
      }
      return ApiResult.failure(e);
    }
  }

  AnimalDetail _detailFromCache(Map<String, dynamic> cached) {
    final animal = AnimalProfile.fromJson(
      cached['animal'] as Map<String, dynamic>,
      fromCache: true,
    );
    final timeline = (cached['timeline'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(
          (e) => AnimalTimelineEvent(
            title: e['title'] as String? ?? '',
            subtitle: e['subtitle'] as String? ?? '',
            at: DateTime.tryParse(e['at'] as String? ?? '') ?? DateTime.now(),
          ),
        )
        .toList();
    final history = (cached['history'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(
          (h) => AnimalHistoryEntry(
            id: h['id'] as String? ?? '',
            title: h['title'] as String? ?? '',
            status: h['status'] as String? ?? '',
            at: h['at'] == null ? null : DateTime.tryParse(h['at'] as String),
          ),
        )
        .toList();
    return AnimalDetail(animal: animal, timeline: timeline, history: history, fromCache: true);
  }

  Future<AnimalDetail> _buildDetail(AnimalProfile animal) async {
    final timeline = <AnimalTimelineEvent>[
      AnimalTimelineEvent(
        title: 'Registered',
        subtitle: animal.name,
        at: animal.createdAt,
      ),
      if (animal.updatedAt.isAfter(animal.createdAt))
        AnimalTimelineEvent(
          title: 'Profile updated',
          subtitle: animal.species,
          at: animal.updatedAt,
        ),
    ];

    final history = <AnimalHistoryEntry>[];
    final requestsResult = await _serviceRequests.listRequests(limit: 100);
    requestsResult.when(
      success: (data) {
        for (final request in data.requests) {
          if (request.animal?.id == animal.id) {
            history.add(
              AnimalHistoryEntry(
                id: request.id,
                title: serviceTypeLabelStatic(request.serviceType),
                status: request.status.apiValue,
                at: DateTime.tryParse(request.submittedAt ?? request.createdAt ?? ''),
              ),
            );
          }
        }
      },
      failure: (_) {},
    );

    return AnimalDetail(animal: animal, timeline: timeline, history: history);
  }

  String serviceTypeLabelStatic(String type) {
    switch (type) {
      case 'CONSULTATION':
        return 'Consultation';
      case 'EMERGENCY':
        return 'Emergency';
      case 'HOME_VISIT':
        return 'Home visit';
      default:
        return type;
    }
  }

  @override
  Future<ApiResult<AnimalProfile>> createAnimal(AnimalInput input) async {
    final body = input.toCreateJson();
    try {
      final data = await postJson(_dio, AnimalApiPaths.animals, body);
      final raw = data['animal'];
      if (raw is! Map<String, dynamic>) {
        return ApiResult.failure(const AppException(message: 'Invalid create response'));
      }
      await clearDraft();
      return ApiResult.success(AnimalProfile.fromJson(raw));
    } on AppException catch (e) {
      if (isTransientNetworkError(e)) {
        await _enqueueCreate(body);
        return ApiResult.failure(
          const AppException(
            message: 'Saved offline — will sync when online',
            code: offlineQueuedCode,
          ),
        );
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<AnimalProfile>> updateAnimal(String id, AnimalInput input) async {
    final body = input.toPatchJson();
    try {
      final data = await patchJson(_dio, AnimalApiPaths.animal(id), body);
      final raw = data['animal'];
      if (raw is! Map<String, dynamic>) {
        return ApiResult.failure(const AppException(message: 'Invalid update response'));
      }
      await clearDraft(animalId: id);
      return ApiResult.success(AnimalProfile.fromJson(raw));
    } on AppException catch (e) {
      if (isTransientNetworkError(e)) {
        await _enqueuePatch(id, body);
        return ApiResult.failure(
          const AppException(
            message: 'Saved offline — will sync when online',
            code: offlineQueuedCode,
          ),
        );
      }
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<AnimalProfile>> deactivateAnimal(String id) async {
    try {
      final data = await patchJson(_dio, AnimalApiPaths.deactivate(id), {});
      final raw = data['animal'];
      if (raw is! Map<String, dynamic>) {
        return ApiResult.failure(const AppException(message: 'Invalid deactivate response'));
      }
      return ApiResult.success(AnimalProfile.fromJson(raw));
    } on AppException catch (e) {
      return ApiResult.failure(e);
    }
  }

  @override
  Future<ApiResult<String>> uploadPhoto(
    String filePath, {
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post<dynamic>(
        AnimalApiPaths.uploadImage,
        data: formData,
        onSendProgress: onProgress,
      );
      final data = ApiEnvelope.unwrapData(response);
      final url = data['profilePhotoUrl'] as String? ?? data['downloadUrl'] as String?;
      if (url == null || url.isEmpty) {
        return ApiResult.failure(
          const AppException(message: 'Upload succeeded but no URL returned'),
        );
      }
      return ApiResult.success(url);
    } on AppException catch (e) {
      return ApiResult.failure(e);
    } on DioException catch (e) {
      return ApiResult.failure(ApiEnvelope.fromDioException(e));
    }
  }

  Future<void> _enqueueCreate(Map<String, dynamic> body) async {
    final sequence = (await _outbox.listAll()).length + 1;
    await _outbox.enqueue(
      OutboxItem(
        idempotencyKey: 'animal-create-$sequence-${DateTime.now().millisecondsSinceEpoch}',
        kind: OutboxKind.animalCreate,
        payload: body,
        clientSequence: sequence,
        attemptCount: 0,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  Future<void> _enqueuePatch(String id, Map<String, dynamic> body) async {
    final sequence = (await _outbox.listAll()).length + 1;
    await _outbox.enqueue(
      OutboxItem(
        idempotencyKey: 'animal-patch-$id-$sequence',
        kind: OutboxKind.animalPatch,
        payload: {'id': id, ...body},
        clientSequence: sequence,
        attemptCount: 0,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  @override
  Future<void> saveDraft(AnimalInput input, {String? animalId}) async {
    final key = animalId == null
        ? LocalCacheContract.animalDraftKey
        : LocalCacheContract.animalEditDraftKey(animalId);
    await _cache.write(key, input.toDraftJson(), LocalCacheContract.caseDraftTtl);
  }

  @override
  Future<AnimalInput?> readDraft({String? animalId}) async {
    final key = animalId == null
        ? LocalCacheContract.animalDraftKey
        : LocalCacheContract.animalEditDraftKey(animalId);
    final cached = await _cache.read(key);
    if (cached == null) return null;
    return AnimalInput.fromDraftJson(cached);
  }

  @override
  Future<void> clearDraft({String? animalId}) async {
    final key = animalId == null
        ? LocalCacheContract.animalDraftKey
        : LocalCacheContract.animalEditDraftKey(animalId);
    await _cache.write(key, {}, const Duration(seconds: 1));
  }
}

final animalRepositoryProvider = Provider<AnimalRepositoryContract>((ref) {
  return AnimalRepository(
    ref.watch(dioProvider),
    ref.watch(localCacheServiceProvider),
    ref.watch(outboxServiceProvider),
    ref.watch(serviceRequestRepositoryProvider),
  );
});

/// Booking dropdown compatibility.
final animalsProvider = FutureProvider<List<AnimalProfile>>((ref) async {
  final result = await ref.read(animalRepositoryProvider).listAnimals(pageSize: 100);
  return result.when(
    success: (page) => page.animals,
    failure: (e) => throw e,
  );
});
