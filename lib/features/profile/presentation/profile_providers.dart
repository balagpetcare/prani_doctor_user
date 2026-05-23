import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/jwt_utils.dart';
import '../../../core/network/auto_refresh_guard.dart';
import '../../../core/error/api_result.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/error/http_error_mapper.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/offline/network_errors.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/session/session_providers.dart';
import '../data/mobile_me_dto.dart';
import '../data/profile_media_models.dart';
import '../data/profile_repository.dart';
import '../data/profile_repository_contract.dart';
import 'profile_locale_controller.dart';
import 'profile_location_draft_provider.dart';

final mobileMeProvider = AsyncNotifierProvider<MobileMeNotifier, MobileMeDto?>(
  MobileMeNotifier.new,
);

class MobileMeNotifier extends AsyncNotifier<MobileMeDto?> {
  bool _reloadInFlight = false;

  void _log(String message) {
    if (kDebugMode) debugPrint('[PROFILE] $message');
  }

  bool _isAuthError(Object error) {
    if (error is! AppException) return false;
    const codes = {
      '401',
      '403',
      '405',
      'METHOD_NOT_ALLOWED',
      'UNAUTHORIZED',
      'UNAUTHORIZED_BEARER_REQUIRED',
      'TOKEN_INVALID',
      'FORBIDDEN_CUSTOMER_REQUIRED',
    };
    return codes.contains(error.code);
  }

  Future<void> _handleAuthFailure(Object error) async {
    if (!_isAuthError(error)) return;
    _log('auth failure — attempting refresh');
    final sessionManager = ref.read(sessionManagerProvider);
    final dio = ref.read(dioProvider);
    final recovered = await sessionManager.recoverFromUnauthorized(dio: dio);
    if (recovered) {
      _log('refresh ok — reloading profile');
      ref.invalidateSelf();
      return;
    }
    _log('refresh failed — invalidating session');
    await sessionManager.invalidateSession(
      reason: 'profile auth failure after refresh',
    );
  }

  Future<bool> _ensureValidSession() async {
    final session = ref.read(sessionControllerProvider.notifier);
    final token = await session.readAccessToken();
    if (token == null ||
        token.isEmpty ||
        !JwtUtils.isValidAccessToken(token) ||
        JwtUtils.isExpired(token)) {
      _log('invalid JWT — clearing session');
      await ref
          .read(sessionManagerProvider)
          .invalidateSession(reason: 'invalid JWT before profile fetch');
      return false;
    }
    return true;
  }

  Future<MobileMeDto?> _loadProfileWithRecovery({
    bool forceRefresh = false,
  }) async {
    if (!await _ensureValidSession()) {
      return null;
    }
    final repo = ref.read(profileRepositoryProvider);

    // cache → api
    final cached = await repo.readCachedProfile();
    if (cached != null && !forceRefresh) {
      _log('[PROFILE_FETCH] serving cached profile');
      unawaited(
        ref.read(profileLocationDraftProvider.notifier).hydrateFromProfile(
          cached,
        ),
      );
      ref.scheduleSilentRefresh(() => _refreshProfileInBackground(repo));
      return cached;
    }

    final result = await repo.getMe(forceRefresh: forceRefresh);
    if (result is ApiSuccess<MobileMeDto>) {
      ref
          .read(profileLocaleControllerProvider.notifier)
          .syncFromProfile(result.data.locale);
      _log('[PROFILE_FETCH] profile loaded from API');
      unawaited(
        ref.read(profileLocationDraftProvider.notifier).hydrateFromProfile(
          result.data,
        ),
      );
      return result.data;
    }

    final error = (result as ApiFailure<MobileMeDto>).error;
    _log('profile fetch failed: ${error.code ?? error.message}');
    await _handleAuthFailure(error);
    final fallback = await repo.readCachedProfile();
    if (fallback != null) {
      _log('profile recovery — using cache');
      return fallback;
    }
    throw error;
  }

  Future<void> _refreshProfileInBackground(
    ProfileRepositoryContract repo,
  ) async {
    final result = await repo.getMe(forceRefresh: true);
    if (result is ApiSuccess<MobileMeDto>) {
      ref
          .read(profileLocaleControllerProvider.notifier)
          .syncFromProfile(result.data.locale);
      state = AsyncData(result.data);
      _log('[PROFILE_REFRESH] background refresh ok');
      if (result.data.canContinueToHome) {
        _log('[CONTINUE_ENABLED] profile ready after background refresh');
      }
    }
  }

  @override
  Future<MobileMeDto?> build() async {
    if (!ref.watch(protectedApisEnabledProvider)) {
      return null;
    }
    return _loadProfileWithRecovery();
  }

  Future<void> profileRefresh({bool forceRefresh = true}) async {
    if (_reloadInFlight) return;
    _reloadInFlight = true;
    final previous = state.valueOrNull;
    if (previous == null) {
      state = const AsyncLoading();
    }
    try {
      _log('[PROFILE_REFRESH] force=$forceRefresh');
      final profile = await _loadProfileWithRecovery(
        forceRefresh: forceRefresh,
      );
      state = AsyncData(profile);
      if (profile?.canContinueToHome == true) {
        _log('[CONTINUE_ENABLED] profile ready after refresh');
      }
    } catch (e, st) {
      _log('profileRefresh error: $e');
      if (previous != null) {
        state = AsyncData(previous);
      } else {
        state = AsyncError(e, st);
      }
    } finally {
      _reloadInFlight = false;
    }
  }

  Future<String?> save(PatchMobileMeInput input) async {
    if (kDebugMode) {
      debugPrint('[PROFILE_SAVE] payload=${input.toJson().keys.join(',')}');
    }
    final result = await ref.read(profileRepositoryProvider).patchMe(input);
    if (result is ApiSuccess<MobileMeDto>) {
      state = AsyncData(result.data);
      if (input.address != null) {
        await ref
            .read(profileLocationDraftProvider.notifier)
            .hydrateFromProfile(result.data);
      }
      if (input.locale != null) {
        ref
            .read(profileLocaleControllerProvider.notifier)
            .syncFromProfile(input.locale!);
      }
      _log('profile saved — refreshing');
      await profileRefresh(forceRefresh: true);
      return null;
    }

    final error = (result as ApiFailure<MobileMeDto>).error;
    if (error.code == offlineQueuedCode) {
      final optimistic = error.cause;
      if (optimistic is MobileMeDto) {
        state = AsyncData(optimistic);
      }
      _log('profile saved offline');
      return null;
    }
    await _handleAuthFailure(error);
    return HttpErrorMapper.profileErrorMessage(error);
  }

  Future<String?> uploadAvatar(String filePath) async {
    final repo = ref.read(profileRepositoryProvider);
    if (repo is! ProfileRepository) {
      return 'Upload unavailable';
    }
    final result = await repo.uploadProfileMedia(
      filePath,
      kind: ProfileMediaKind.avatar,
    );
    if (result is ApiSuccess<ProfileMediaUploadResult>) {
      final upload = result.data;
      final mainUrl = upload.avatarUrl ?? upload.url;
      final thumbUrl = upload.avatarThumbUrl ?? upload.thumbUrl;
      final current = state.value;
      if (current != null && mainUrl != null) {
        state = AsyncData(
          current.copyWith(
            profilePhotoUrl: mainUrl,
            profilePhotoThumbUrl: thumbUrl ?? mainUrl,
          ),
        );
      } else {
        await profileRefresh(forceRefresh: true);
      }
      _log('[AVATAR_APPLY] url=$mainUrl thumb=$thumbUrl');
      return null;
    }
    final error = (result as ApiFailure<ProfileMediaUploadResult>).error;
    if (error.code == 'UPLOAD_BUSY') return null;
    _log('[AVATAR_APPLY] failed ${error.code ?? error.message}');
    await _handleAuthFailure(error);
    return HttpErrorMapper.profileErrorMessage(error);
  }

  Future<String?> uploadCover(String filePath) async {
    final repo = ref.read(profileRepositoryProvider);
    if (repo is! ProfileRepository) {
      return 'Upload unavailable';
    }
    final result = await repo.uploadProfileMedia(
      filePath,
      kind: ProfileMediaKind.cover,
    );
    if (result is ApiSuccess<ProfileMediaUploadResult>) {
      final upload = result.data;
      final mainUrl = upload.coverUrl ?? upload.url;
      final thumbUrl = upload.coverThumbUrl ?? upload.thumbUrl;
      final current = state.value;
      if (current != null && mainUrl != null) {
        state = AsyncData(
          current.copyWith(
            coverPhotoUrl: mainUrl,
            coverPhotoThumbUrl: thumbUrl ?? mainUrl,
          ),
        );
      } else {
        await profileRefresh(forceRefresh: true);
      }
      _log('[MEDIA_PROFILE] cover url=$mainUrl thumb=$thumbUrl');
      return null;
    }
    final error = (result as ApiFailure<ProfileMediaUploadResult>).error;
    if (error.code == 'UPLOAD_BUSY') return null;
    _log('[MEDIA_PROFILE] cover failed: ${error.code ?? error.message}');
    await _handleAuthFailure(error);
    return HttpErrorMapper.profileErrorMessage(error);
  }

  Future<String?> removeMedia(ProfileMediaKind kind) async {
    final repo = ref.read(profileRepositoryProvider);
    if (repo is! ProfileRepository) return 'Remove unavailable';
    final result = await repo.removeProfileMedia(kind);
    if (result is ApiSuccess<void>) {
      final current = state.value;
      if (current != null) {
        state = AsyncData(
          kind == ProfileMediaKind.avatar
              ? current.copyWith(
                  profilePhotoUrl: null,
                  profilePhotoThumbUrl: null,
                )
              : current.copyWith(coverPhotoUrl: null, coverPhotoThumbUrl: null),
        );
      } else {
        await profileRefresh(forceRefresh: true);
      }
      _log('[MEDIA_PROFILE] ${kind.name} removed');
      return null;
    }
    _log('[MEDIA_PROFILE] ${kind.name} remove failed');
    return HttpErrorMapper.profileErrorMessage(
      (result as ApiFailure<void>).error,
    );
  }

  Future<void> reload({bool forceRefresh = false}) =>
      profileRefresh(forceRefresh: forceRefresh);

  void hydrate(MobileMeDto profile) {
    ref
        .read(profileLocaleControllerProvider.notifier)
        .syncFromProfile(profile.locale);
    state = AsyncData(profile);
    _log('profile hydrated from boot');
  }
}

final profileLocaleControllerProvider =
    StateNotifierProvider<ProfileLocaleController, Locale?>((ref) {
      return ProfileLocaleController();
    });
