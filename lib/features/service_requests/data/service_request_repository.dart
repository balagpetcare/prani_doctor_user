import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_result.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_helpers.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/offline/local_cache_contract.dart';
import '../../../core/offline/network_errors.dart';
import '../../doctors/data/provider_dto.dart';
import '../../offline/data/local_cache_service.dart';
import '../../offline/data/outbox_item.dart';
import '../../offline/data/outbox_service.dart';
import '../../offline/offline_providers.dart';
import 'service_request_api_paths.dart';
import 'service_request_dto.dart';

enum InboxSegment { active, completed, closed, all }

class ServiceRequestRepository {
  ServiceRequestRepository(this._dio, this._cache, this._outbox);

  final Dio _dio;
  final LocalCacheService _cache;
  final OutboxService _outbox;

  Future<ApiResult<ServiceRequestListResultDto>> listRequests({
    int limit = 50,
    int offset = 0,
    ServiceRequestStatus? status,
  }) async {
    try {
      final data = await getJson(
        _dio,
        ServiceRequestApiPaths.serviceRequests,
        queryParameters: {
          'limit': limit,
          'offset': offset,
          if (status != null) 'status': status.apiValue,
        },
      );
      await _cache.write(
        LocalCacheContract.serviceRequestsListKey,
        data,
        LocalCacheContract.profileTtl,
      );
      final requests = (data['requests'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ServiceRequestDto.fromJson)
          .toList();
      return ApiResult.success(
        ServiceRequestListResultDto(
          requests: requests,
          total: data['total'] as int? ?? requests.length,
        ),
      );
    } on AppException catch (e) {
      final cached = await _cache.read(LocalCacheContract.serviceRequestsListKey);
      if (cached != null) {
        final requests = (cached['requests'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ServiceRequestDto.fromJson)
            .toList();
        return ApiResult.success(
          ServiceRequestListResultDto(
            requests: requests,
            total: cached['total'] as int? ?? requests.length,
          ),
        );
      }
      return ApiResult.failure(e);
    } catch (e) {
      return ApiResult.failure(
        AppException(message: 'Could not load appointments', cause: e),
      );
    }
  }

  Future<ApiResult<ServiceRequestDto>> getRequest(String id) async {
    try {
      final data = await getJson(_dio, ServiceRequestApiPaths.serviceRequest(id));
      final request = data['request'];
      if (request is! Map<String, dynamic>) {
        return ApiResult.failure(const AppException(message: 'Appointment not found'));
      }
      return ApiResult.success(ServiceRequestDto.fromJson(request));
    } on AppException catch (e) {
      return ApiResult.failure(e);
    } catch (e) {
      return ApiResult.failure(
        AppException(message: 'Could not load appointment', cause: e),
      );
    }
  }

  Future<ApiResult<ServiceRequestTimelineDto>> getTimeline(String id) async {
    try {
      final data = await getJson(_dio, ServiceRequestApiPaths.timeline(id));
      return ApiResult.success(ServiceRequestTimelineDto.fromJson(data));
    } on AppException catch (e) {
      return ApiResult.failure(e);
    } catch (e) {
      return ApiResult.failure(
        AppException(message: 'Could not load history', cause: e),
      );
    }
  }

  Future<ApiResult<ServiceRequestDto>> cancelRequest(
    String id, {
    String? cancelReason,
  }) async {
    try {
      final data = await postJson(
        _dio,
        ServiceRequestApiPaths.cancel(id),
        {if (cancelReason != null) 'cancelReason': cancelReason},
      );
      final request = data['request'];
      if (request is! Map<String, dynamic>) {
        return ApiResult.failure(const AppException(message: 'Invalid cancel response'));
      }
      return ApiResult.success(ServiceRequestDto.fromJson(request));
    } on AppException catch (e) {
      return ApiResult.failure(e);
    } catch (e) {
      return ApiResult.failure(
        AppException(message: 'Could not cancel appointment', cause: e),
      );
    }
  }

  Future<ApiResult<ServiceRequestDto>> createRequest(
    CreateServiceRequestInput input,
  ) async {
    final body = input.toJson();
    try {
      final data = await postJson(
        _dio,
        ServiceRequestApiPaths.serviceRequests,
        body,
      );
      final request = data['request'];
      if (request is! Map<String, dynamic>) {
        return ApiResult.failure(const AppException(message: 'Invalid booking response'));
      }
      return ApiResult.success(ServiceRequestDto.fromJson(request));
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
    } catch (e) {
      return ApiResult.failure(AppException(message: 'Booking failed', cause: e));
    }
  }

  Future<void> _enqueueCreate(Map<String, dynamic> body) async {
    final sequence = (await _outbox.listAll()).length + 1;
    await _outbox.enqueue(
      OutboxItem(
        idempotencyKey: 'sr-$sequence-${DateTime.now().millisecondsSinceEpoch}',
        kind: OutboxKind.serviceRequest,
        payload: body,
        clientSequence: sequence,
        attemptCount: 0,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  Future<ApiResult<List<ServiceCategoryDto>>> listCategories() async {
    try {
      final data = await getJson(_dio, ServiceRequestApiPaths.serviceCategories);
      final items = (data['categories'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ServiceCategoryDto.fromJson)
          .toList();
      return ApiResult.success(items);
    } on AppException catch (e) {
      return ApiResult.failure(e);
    } catch (e) {
      return ApiResult.failure(AppException(message: 'Could not load categories', cause: e));
    }
  }

}

List<ServiceRequestDto> filterRequestsBySegment(
  List<ServiceRequestDto> requests,
  InboxSegment segment,
) {
  switch (segment) {
    case InboxSegment.active:
      return requests.where((r) => r.status.isActive).toList();
    case InboxSegment.completed:
      return requests.where((r) => r.status.isCompleted).toList();
    case InboxSegment.closed:
      return requests.where((r) => r.status.isClosed).toList();
    case InboxSegment.all:
      return requests;
  }
}

final serviceRequestRepositoryProvider = Provider<ServiceRequestRepository>((ref) {
  return ServiceRequestRepository(
    ref.watch(dioProvider),
    ref.watch(localCacheServiceProvider),
    ref.watch(outboxServiceProvider),
  );
});

final inboxSegmentProvider = StateProvider<InboxSegment>((ref) => InboxSegment.active);

final serviceRequestListProvider = FutureProvider<List<ServiceRequestDto>>((ref) async {
  final segment = ref.watch(inboxSegmentProvider);
  final result = await ref.read(serviceRequestRepositoryProvider).listRequests();
  return result.when(
    success: (data) => filterRequestsBySegment(data.requests, segment),
    failure: (e) => throw e,
  );
});

final serviceRequestDetailProvider =
    FutureProvider.family<ServiceRequestDto, String>((ref, id) async {
  final result = await ref.read(serviceRequestRepositoryProvider).getRequest(id);
  return result.when(
    success: (data) => data,
    failure: (e) => throw e,
  );
});

final serviceRequestTimelineProvider =
    FutureProvider.family<ServiceRequestTimelineDto, String>((ref, id) async {
  final result = await ref.read(serviceRequestRepositoryProvider).getTimeline(id);
  return result.when(
    success: (data) => data,
    failure: (e) => throw e,
  );
});

final serviceCategoriesProvider = FutureProvider<List<ServiceCategoryDto>>((ref) async {
  final result = await ref.read(serviceRequestRepositoryProvider).listCategories();
  return result.when(
    success: (data) => data,
    failure: (e) => throw e,
  );
});
