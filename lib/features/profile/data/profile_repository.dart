import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_result.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/flexible_http.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/offline/local_cache_contract.dart';
import '../../../core/offline/network_errors.dart';
import '../../shared/upload/services/upload_service.dart';
import '../../offline/data/local_cache_service.dart';
import '../../offline/data/outbox_item.dart';
import '../../offline/data/outbox_service.dart';
import '../../offline/offline_providers.dart';
import 'mobile_me_dto.dart';
import 'profile_api_paths.dart';
import 'profile_fetch_policy.dart';
import 'profile_media_models.dart';
import 'profile_repository_contract.dart';
import '../services/profile_media_service.dart';

/// Production profile repository with cache, offline queue, and upload support.
class ProfileRepository implements ProfileRepositoryContract {
  ProfileRepository(
    this._dio,
    this._cache,
    this._outbox,
    this._uploads,
    this._media,
  );

  final Dio _dio;
  final LocalCacheService _cache;
  final OutboxService _outbox;
  final UploadService _uploads;
  final ProfileMediaService _media;

  Future<ApiResult<MobileMeDto>>? _getMeInFlight;
  Future<ApiResult<MobileMeDto>>? _patchInFlight;

  @override
  Future<MobileMeDto?> readCachedProfile() async {
    final cached = await _cache.read(LocalCacheContract.profileKey);
    if (cached == null) return null;
    return _mergeCachedAddress(MobileMeDto.fromJson(cached));
  }

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
    if (profile.address != null) {
      await _writeAddressCache(profile.address);
      return profile;
    }
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

    final future = _fetchMeWithRetry();
    _getMeInFlight = future;
    try {
      return await future;
    } finally {
      _getMeInFlight = null;
    }
  }

  Future<ApiResult<MobileMeDto>> _fetchMeWithRetry() async {
    AppException? lastError;

    for (
      var attempt = 1;
      attempt <= ProfileFetchPolicy.maxAttempts;
      attempt++
    ) {
      try {
        final data = await getJsonFlexible(
          _dio,
          ProfileApiPaths.me,
          logTag: 'PROFILE',
        ).timeout(ProfileFetchPolicy.requestTimeout);
        await _writeProfileCache(data);
        final profile = await _mergeCachedAddress(MobileMeDto.fromJson(data));
        if (kDebugMode) {
          debugPrint(
            '[PROFILE_FETCH] ok union=${profile.address?.unionId} village=${profile.address?.villageId}',
          );
        }
        return ApiResult.success(profile);
      } on AppException catch (e) {
        lastError = e;
        if (!ProfileFetchPolicy.isRetryable(e) ||
            attempt >= ProfileFetchPolicy.maxAttempts) {
          break;
        }
        if (kDebugMode) {
          debugPrint(
            '[PROFILE] retry $attempt/${ProfileFetchPolicy.maxAttempts} (${e.code})',
          );
        }
      } on Object catch (e) {
        lastError = AppException(message: 'Failed to load profile', cause: e);
        if (attempt >= ProfileFetchPolicy.maxAttempts) break;
      }
    }

    final cached = await _cache.read(LocalCacheContract.profileKey);
    if (cached != null) {
      final profile = await _mergeCachedAddress(MobileMeDto.fromJson(cached));
      return ApiResult.success(profile);
    }

    return ApiResult.failure(
      lastError ?? const AppException(message: 'Failed to load profile'),
    );
  }

  @override
  Future<ApiResult<MobileMeDto>> patchMe(PatchMobileMeInput input) async {
    if (_patchInFlight != null) {
      return _patchInFlight!;
    }

    if (!input.hasPayload) {
      return const ApiResult.failure(
        AppException(message: 'No changes to save'),
      );
    }

    final future = _patchMe(input);
    _patchInFlight = future;
    try {
      return await future;
    } finally {
      _patchInFlight = null;
    }
  }

  Future<ApiResult<MobileMeDto>> _patchMe(PatchMobileMeInput input) async {
    final body = input.toJson();

    try {
      final data = await patchJsonFlexible(
        _dio,
        ProfileApiPaths.me,
        body,
        logTag: 'PROFILE',
      ).timeout(ProfileFetchPolicy.requestTimeout);
      if (input.address != null) {
        await _writeAddressCache(input.address);
        if (kDebugMode) {
          debugPrint(
            '[LOCATION_SAVE] union=${input.address!.unionId} village=${input.address!.villageId}',
          );
        }
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
          final profile = await _mergeCachedAddress(
            MobileMeDto.fromJson(merged),
          );
          return ApiResult.failure(
            AppException(
              message: 'Saved offline — will sync when online',
              code: offlineQueuedCode,
              cause: profile,
            ),
          );
        }
        return const ApiResult.failure(
          AppException(
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

  Future<ApiResult<ProfileMediaUploadResult>> uploadProfileMedia(
    String filePath, {
    required ProfileMediaKind kind,
    void Function(int sent, int total)? onProgress,
  }) async {
    final result = kind == ProfileMediaKind.avatar
        ? await _media.uploadAvatar(filePath, onProgress: onProgress)
        : await _media.uploadCover(filePath, onProgress: onProgress);

    return result.when(
      success: (upload) async {
        final cached = await _cache.read(LocalCacheContract.profileKey);
        if (cached != null) {
          final avatarMain = upload.avatarUrl ?? upload.url;
          final avatarThumb = upload.avatarThumbUrl ?? upload.thumbUrl;
          final coverMain = upload.coverUrl ?? upload.url;
          final coverThumb = upload.coverThumbUrl ?? upload.thumbUrl;

          if (kind == ProfileMediaKind.avatar) {
            if (avatarMain != null) {
              cached['profilePhotoUrl'] = avatarMain;
              cached['profileImageUrl'] = avatarMain;
              cached['avatarUrl'] = avatarMain;
            }
            if (avatarThumb != null) {
              cached['profilePhotoThumbUrl'] = avatarThumb;
              cached['profileImageThumbUrl'] = avatarThumb;
              cached['avatarThumbUrl'] = avatarThumb;
            }
          } else {
            if (coverMain != null) {
              cached['coverPhotoUrl'] = coverMain;
              cached['coverImageUrl'] = coverMain;
              cached['coverUrl'] = coverMain;
            }
            if (coverThumb != null) {
              cached['coverPhotoThumbUrl'] = coverThumb;
              cached['coverImageThumbUrl'] = coverThumb;
              cached['coverThumbUrl'] = coverThumb;
            }
          }
          await _writeProfileCache(cached);
        }
        return ApiResult.success(upload);
      },
      failure: ApiResult.failure,
    );
  }

  Future<ApiResult<void>> removeProfileMedia(ProfileMediaKind kind) async {
    final result = kind == ProfileMediaKind.avatar
        ? await _media.removeAvatar()
        : await _media.removeCover();
    return result.when(
      success: (_) async {
        final cached = await _cache.read(LocalCacheContract.profileKey);
        if (cached != null) {
          if (kind == ProfileMediaKind.avatar) {
            cached.remove('profilePhotoUrl');
            cached.remove('profilePhotoThumbUrl');
            cached.remove('profileImageUrl');
            cached.remove('profileImageThumbUrl');
          } else {
            cached.remove('coverPhotoUrl');
            cached.remove('coverPhotoThumbUrl');
            cached.remove('coverImageUrl');
            cached.remove('coverImageThumbUrl');
          }
          await _writeProfileCache(cached);
        }
        return const ApiResult.success(null);
      },
      failure: ApiResult.failure,
    );
  }

  @override
  Future<ApiResult<String>> uploadProfilePhoto(String filePath) async {
    final result = await _uploads.uploadProfileImage(filePath);
    return result.when(
      success: (upload) async {
        final url = upload.profilePhotoUrl ?? upload.url;
        if (url.isEmpty) {
          return const ApiResult.failure(
            AppException(
              message: 'Upload succeeded but no photo URL returned',
            ),
          );
        }
        final cached = await _cache.read(LocalCacheContract.profileKey);
        if (cached != null) {
          cached['profilePhotoUrl'] = url;
          await _writeProfileCache(cached);
        }
        return ApiResult.success(url);
      },
      failure: ApiResult.failure,
    );
  }

  Future<void> _enqueuePatch({required Map<String, dynamic> body}) async {
    if (body.isEmpty) return;
    final sequence = (await _outbox.listAll()).length + 1;
    await _outbox.enqueue(
      OutboxItem(
        idempotencyKey:
            'profile-$sequence-${DateTime.now().millisecondsSinceEpoch}',
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
    ref.watch(uploadServiceProvider),
    ref.watch(profileMediaServiceProvider),
  );
});
