import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_env.dart';
import '../../../../core/error/api_result.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/network/api_envelope.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/network_providers.dart';
import '../models/upload_purpose.dart';
import '../models/upload_result.dart';
import 'upload_api_paths.dart';
import 'upload_validation.dart';

class UploadService {
  UploadService(this._dio, this._env);

  final Dio _dio;
  final AppEnv _env;

  static const _maxAttempts = 3;

  String get uploadBaseUrl {
    const fromEnv = String.fromEnvironment('UPLOAD_URL');
    if (fromEnv.trim().isNotEmpty) {
      return fromEnv.trim().replaceAll(RegExp(r'/+$'), '');
    }
    return _env.apiBaseUrl;
  }

  Future<ApiResult<UploadResult>> uploadFile({
    required String filePath,
    required String endpoint,
    Map<String, dynamic>? fields,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
    UploadKind? expectedKind,
    int? maxBytes,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return const ApiResult.failure(AppException(message: 'File not found'));
    }

    final sizeBytes = await file.length();
    final validationError = UploadValidation.validateFile(
      path: filePath,
      sizeBytes: sizeBytes,
      expectedKind: expectedKind,
      maxBytes: maxBytes,
    );
    if (validationError != null) {
      return ApiResult.failure(AppException(message: validationError));
    }

    final formMap = <String, dynamic>{
      'file': await MultipartFile.fromFile(filePath),
      ...?fields,
    };

    return _postMultipart(
      endpoint: endpoint,
      formData: FormData.fromMap(formMap),
      filePath: filePath,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  Future<ApiResult<UploadResult>> uploadWithPurpose({
    required String filePath,
    required UploadPurpose purpose,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) {
    return uploadFile(
      filePath: filePath,
      endpoint: UploadApiPaths.upload,
      fields: {'purpose': purpose.apiValue},
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  Future<ApiResult<UploadResult>> uploadProfileImage(
    String filePath, {
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) {
    return uploadFile(
      filePath: filePath,
      endpoint: UploadApiPaths.profileImage,
      expectedKind: UploadKind.image,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  Future<ApiResult<UploadResult>> uploadAnimalPhoto(
    String filePath, {
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) {
    return uploadFile(
      filePath: filePath,
      endpoint: UploadApiPaths.upload,
      fields: {'purpose': UploadPurpose.animalPhoto.apiValue},
      expectedKind: UploadKind.image,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  Future<ApiResult<UploadResult>> uploadCoverImage(
    String filePath, {
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) {
    return uploadFile(
      filePath: filePath,
      endpoint: UploadApiPaths.coverImage,
      expectedKind: UploadKind.image,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  Future<ApiResult<UploadResult>> uploadSupportAttachment(
    String filePath, {
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) {
    return uploadFile(
      filePath: filePath,
      endpoint: UploadApiPaths.supportUpload,
      maxBytes: UploadValidation.defaultMaxSupportBytes,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  Future<ApiResult<void>> deleteFile(String fileId) async {
    try {
      await _dio.delete<void>(UploadApiPaths.delete(fileId));
      return const ApiResult.success(null);
    } on AppException catch (e) {
      return ApiResult.failure(e);
    } on DioException catch (e) {
      return ApiResult.failure(ApiEnvelope.fromDioException(e));
    } catch (e) {
      return ApiResult.failure(
        AppException(message: 'Failed to delete file', cause: e),
      );
    }
  }

  Future<ApiResult<String>> fetchPresignedUrl({
    required UploadPurpose purpose,
    required String fileName,
    String method = 'PUT',
    String? fileId,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        UploadApiPaths.presigned,
        queryParameters: {
          'purpose': purpose.apiValue,
          'fileName': fileName,
          'method': method,
          'fileId': ?fileId,
        },
      );
      final data = ApiEnvelope.unwrapData(response);
      final url = data['url'] as String?;
      if (url == null || url.isEmpty) {
        return const ApiResult.failure(
          AppException(message: 'Presigned URL missing from response'),
        );
      }
      return ApiResult.success(url);
    } on AppException catch (e) {
      return ApiResult.failure(e);
    } on DioException catch (e) {
      return ApiResult.failure(ApiEnvelope.fromDioException(e));
    } catch (e) {
      return ApiResult.failure(
        AppException(message: 'Failed to fetch presigned URL', cause: e),
      );
    }
  }

  Future<ApiResult<UploadResult>> _postMultipart({
    required String endpoint,
    required FormData formData,
    required String filePath,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    Object? lastError;

    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        final response = await _dio.post<dynamic>(
          endpoint,
          data: formData,
          onSendProgress: onProgress,
          cancelToken: cancelToken,
          options: Options(
            sendTimeout: _env.connectTimeout,
            receiveTimeout: _env.receiveTimeout,
          ),
        );
        final data = ApiEnvelope.unwrapData(response);
        return ApiResult.success(
          UploadResult.fromJson(data, localPath: filePath),
        );
      } on DioException catch (e) {
        if (CancelToken.isCancel(e)) {
          return const ApiResult.failure(
            AppException(message: 'Upload cancelled', code: 'CANCELLED'),
          );
        }
        lastError = e;
        final retryable = _isRetryable(e);
        if (!retryable || attempt == _maxAttempts) {
          return ApiResult.failure(ApiEnvelope.fromDioException(e));
        }
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      } on AppException catch (e) {
        return ApiResult.failure(e);
      } catch (e) {
        lastError = e;
        if (attempt == _maxAttempts) {
          return ApiResult.failure(
            AppException(message: 'Upload failed', cause: e),
          );
        }
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      }
    }

    return ApiResult.failure(
      AppException(message: 'Upload failed', cause: lastError),
    );
  }

  bool _isRetryable(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return true;
    }
    final status = error.response?.statusCode;
    return status == 503 || status == 502 || status == 504;
  }
}

final uploadServiceProvider = Provider<UploadService>((ref) {
  return UploadService(ref.watch(dioProvider), ref.watch(appEnvProvider));
});
