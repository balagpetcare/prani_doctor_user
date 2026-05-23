import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_result.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/dio_provider.dart';
import '../data/profile_media_models.dart';
import '../services/profile_media_upload_lock.dart';

/// HTTP layer for profile avatar/cover upload and delete.
class ProfileMediaRepository {
  ProfileMediaRepository(this._dio);

  final Dio _dio;

  static const _maxAttempts = 1;

  final _lock = ProfileMediaUploadLock.instance;

  Future<ApiResult<ProfileMediaUploadResult>> uploadAvatar(
    String filePath, {
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) {
    return _upload(
      filePath: filePath,
      fieldName: 'avatar',
      endpoint: ProfileMediaApiPaths.avatar,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  Future<ApiResult<ProfileMediaUploadResult>> uploadCover(
    String filePath, {
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) {
    return _upload(
      filePath: filePath,
      fieldName: 'cover',
      endpoint: ProfileMediaApiPaths.cover,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  Future<ApiResult<ProfileMediaUploadResult>> removeAvatar() {
    return _delete(ProfileMediaApiPaths.avatar);
  }

  Future<ApiResult<ProfileMediaUploadResult>> removeCover() {
    return _delete(ProfileMediaApiPaths.cover);
  }

  Future<ApiResult<ProfileMediaUploadResult>> _delete(String endpoint) async {
    _logReq('DELETE', endpoint);
    try {
      final response = await _dio.delete<dynamic>(endpoint);
      final data = ApiEnvelope.unwrapData(response);
      final result = ProfileMediaUploadResult.fromJson(data);
      _logRes(endpoint, response.statusCode, result: result);
      return ApiResult.success(result);
    } on AppException catch (e) {
      _logRes(endpoint, null, error: e.message);
      return ApiResult.failure(e);
    } on DioException catch (e) {
      final err = ApiEnvelope.fromDioException(e);
      _logRes(endpoint, e.response?.statusCode, error: err.message);
      return ApiResult.failure(err);
    }
  }

  Future<ApiResult<ProfileMediaUploadResult>> _upload({
    required String filePath,
    required String fieldName,
    required String endpoint,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final kind = fieldName == 'avatar'
        ? ProfileMediaKind.avatar
        : ProfileMediaKind.cover;
    final token = _lock.acquire(kind);
    if (token == null) {
      return const ApiResult.failure(
        AppException(
          message: 'Upload already in progress',
          code: 'UPLOAD_BUSY',
        ),
      );
    }

    Object? lastError;

    try {
      for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
        try {
          final file = File(filePath);
          final fileSize = await file.length();
          final multipart = await MultipartFile.fromFile(
            filePath,
            filename: '$fieldName.webp',
          );
          final form = FormData.fromMap({fieldName: multipart});
          _logUpload(
            kind: kind,
            endpoint: endpoint,
            field: fieldName,
            path: filePath,
            size: fileSize,
          );
          final response = await _dio.post<dynamic>(
            endpoint,
            data: form,
            onSendProgress: onProgress,
            cancelToken: cancelToken ?? token,
          );
          final data = ApiEnvelope.unwrapData(response);
          final result = ProfileMediaUploadResult.fromJson(data);
          _logRes(endpoint, response.statusCode, result: result);
          return ApiResult.success(result);
        } on DioException catch (e) {
          if (CancelToken.isCancel(e)) {
            return const ApiResult.failure(
              AppException(
                message: 'Upload cancelled',
                code: 'CANCELLED',
              ),
            );
          }
          lastError = e;
          final err = ApiEnvelope.fromDioException(e);
          _logRes(endpoint, e.response?.statusCode, error: err.message);
          return ApiResult.failure(err);
        } on AppException catch (e) {
          _logRes(endpoint, null, error: e.message);
          return ApiResult.failure(e);
        } catch (e) {
          lastError = e;
          if (attempt == _maxAttempts) {
            return ApiResult.failure(
              AppException(message: 'Upload failed', cause: e),
            );
          }
        }
      }
    } finally {
      _lock.release(kind);
    }

    return ApiResult.failure(
      AppException(message: 'Upload failed', cause: lastError),
    );
  }

  void _logUpload({
    required ProfileMediaKind kind,
    required String endpoint,
    required String field,
    required String path,
    required int size,
  }) {
    if (!kDebugMode) return;
    if (kind == ProfileMediaKind.avatar) {
      debugPrint(
        '[AVATAR_UPLOAD] POST $endpoint field=$field '
        'size=${(size / 1024).round()}KB file=$path',
      );
      return;
    }
    debugPrint(
      '[MEDIA_UPLOAD] kind=${kind.name} POST $endpoint field=$field '
      'size=${(size / 1024).round()}KB file=$path',
    );
  }

  void _logReq(
    String method,
    String endpoint, {
    String? field,
    String? path,
    int? size,
    String? mime,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '[MEDIA_REQ] $method $endpoint'
      '${field != null ? ' field=$field' : ''}'
      '${path != null ? ' file=$path' : ''}'
      '${size != null ? ' size=${(size / 1024).round()}KB' : ''}'
      '${mime != null ? ' mime=$mime' : ''}',
    );
  }

  void _logRes(
    String endpoint,
    int? status, {
    ProfileMediaUploadResult? result,
    String? error,
  }) {
    if (!kDebugMode) return;
    if (error != null) {
      debugPrint('[MEDIA_RES] $endpoint status=$status error=$error');
      return;
    }
    debugPrint(
      '[MEDIA_RES] $endpoint status=$status '
      'url=${result?.url} avatar=${result?.avatarUrl} cover=${result?.coverUrl}',
    );
  }
}

final profileMediaRepositoryProvider = Provider<ProfileMediaRepository>((ref) {
  return ProfileMediaRepository(ref.watch(dioProvider));
});
