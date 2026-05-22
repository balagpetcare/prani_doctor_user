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
import 'mobile_me_dto.dart';
import 'profile_api_paths.dart';
import 'profile_repository_contract.dart';

/// Production profile repository with cache, offline queue, and upload support.
class ProfileRepository implements ProfileRepositoryContract {
  ProfileRepository(this._dio, this._cache, this._outbox);

  final Dio _dio;
  final LocalCacheService _cache;
  final OutboxService _outbox;

  Future<ApiResult<MobileMeDto>>? _getMeInFlight;
  Future<ApiResult<MobileMeDto>>? _patchInFlight;

  @override
  Future<MobileMeAddressDto?> readCachedAddress() async {
    final cached = await _cache.read(LocalCacheContract.profileAddressKey);
    if (cached == null) return null;
    return MobileMeAddressDto.fromJson(cached);
  }

  Future<void> _writeAddressCache(MobileMeAddressDto? address) async {
    if (address == null) return;
    await _cache.write(
      LocalCacheContract.profileAddressKey,
      address.toJson(),
      LocalCacheContract.profileTtl,
    );
  }

  Future<MobileMeDto> _mergeCachedAddress(MobileMeDto profile) async {
    final cachedAddress = await readCachedAddress();
    return profile.mergeAddress(cachedAddress);
  }

  Future<void> _writeProfileCache(Map<String, dynamic> data) async {
    await _cache.write(
      LocalCacheContract.profileKey,
      data,
      LocalCacheContract.profileTtl,
    );
  }

  @override
  Future<ApiResult<MobileMeDto>> getMe({bool forceRefresh = false}) async {
    if (!forceRefresh && _getMeInFlight != null) {
      return _getMeInFlight!;
    }

    final future = _fetchMe();
    _getMeInFlight = future;
    try {
      return await future;
    } finally {
      _getMeInFlight = null;
    }
  }

  Future<ApiResult<MobileMeDto>> _fetchMe() async {
    try {
      final data = await getJson(_dio, ProfileApiPaths.me);
      await _writeProfileCache(data);
      final profile = await _mergeCachedAddress(MobileMeDto.fromJson(data));
      return ApiResult.success(profile);
    } on AppException catch (e) {
      final cached = await _cache.read(LocalCacheContract.profileKey);
      if (cached != null) {
        final profile =
            await _mergeCachedAddress(MobileMeDto.fromJson(cached));
        return ApiResult.success(profile);
      }
      return ApiResult.failure(e);
    } catch (e) {
      return ApiResult.failure(
        AppException(message: 'Failed to load profile', cause: e),
      );
    }
  }

  @override
  Future<ApiResult<MobileMeDto>> patchMe(PatchMobileMeInput input) async {
    if (_patchInFlight != null) {
      return _patchInFlight!;
    }

    final body = input.toJson();
    if (body.isEmpty) {
      return ApiResult.failure(const AppException(message: 'No changes to save'));
    }

    final future = _patchMe(body, input);
    _patchInFlight = future;
    try {
      return await future;
    } finally {
      _patchInFlight = null;
    }
  }

  Future<ApiResult<MobileMeDto>> _patchMe(
    Map<String, dynamic> body,
    PatchMobileMeInput input,
  ) async {
    try {
      final data = await patchJson(_dio, ProfileApiPaths.me, body);
      if (input.address != null) {
        await _writeAddressCache(input.address);
      }
      await _writeProfileCache(data);
      final profile = await _mergeCachedAddress(MobileMeDto.fromJson(data));
      return ApiResult.success(profile);
    } on AppException catch (e) {
      if (isTransientNetworkError(e)) {
        await _enqueuePatch(body: body);
        if (input.address != null) {
          await _writeAddressCache(input.address);
        }
        final cached = await _cache.read(LocalCacheContract.profileKey);
        if (cached != null) {
          final merged = Map<String, dynamic>.from(cached)..addAll(body);
          if (input.address != null) {
            merged['address'] = input.address!.toJson();
          }
          await _writeProfileCache(merged);
          final profile =
              await _mergeCachedAddress(MobileMeDto.fromJson(merged));
          return ApiResult.failure(
            AppException(
              message: 'Saved offline — will sync when online',
              code: offlineQueuedCode,
              cause: profile,
            ),
          );
        }
        return ApiResult.failure(
          const AppException(
            message: 'Saved offline — will sync when online',
            code: offlineQueuedCode,
          ),
        );
      }
      return ApiResult.failure(e);
    } catch (e) {
      return ApiResult.failure(
        AppException(message: 'Failed to update profile', cause: e),
      );
    }
  }

  @override
  Future<ApiResult<String>> uploadProfilePhoto(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post<dynamic>(
        ProfileApiPaths.uploadProfileImage,
        data: formData,
      );
      final data = ApiEnvelope.unwrapData(response);
      final url = data['profilePhotoUrl'] as String?;
      if (url == null || url.isEmpty) {
        return ApiResult.failure(
          const AppException(message: 'Upload succeeded but no photo URL returned'),
        );
      }

      final cached = await _cache.read(LocalCacheContract.profileKey);
      if (cached != null) {
        cached['profilePhotoUrl'] = url;
        await _writeProfileCache(cached);
      }

      return ApiResult.success(url);
    } on AppException catch (e) {
      return ApiResult.failure(e);
    } on DioException catch (e) {
      return ApiResult.failure(ApiEnvelope.fromDioException(e));
    } catch (e) {
      return ApiResult.failure(
        AppException(message: 'Failed to upload photo', cause: e),
      );
    }
  }

  Future<void> _enqueuePatch({required Map<String, dynamic> body}) async {
    if (body.isEmpty) return;
    final sequence = (await _outbox.listAll()).length + 1;
    await _outbox.enqueue(
      OutboxItem(
        idempotencyKey: 'profile-$sequence-${DateTime.now().millisecondsSinceEpoch}',
        kind: OutboxKind.profilePatch,
        payload: body,
        clientSequence: sequence,
        attemptCount: 0,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }
}

final profileRepositoryProvider = Provider<ProfileRepositoryContract>((ref) {
  return ProfileRepository(
    ref.watch(dioProvider),
    ref.watch(localCacheServiceProvider),
    ref.watch(outboxServiceProvider),
  );
});
