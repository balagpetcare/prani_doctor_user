import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_result.dart';
import '../data/profile_media_models.dart';
import '../data/profile_media_repository.dart';

/// Profile media orchestration — delegates upload/delete to [ProfileMediaRepository].
class ProfileMediaService {
  ProfileMediaService(this._repository);

  final ProfileMediaRepository _repository;

  Future<ApiResult<ProfileMediaUploadResult>> uploadAvatar(
    String filePath, {
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) {
    return _repository.uploadAvatar(
      filePath,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  Future<ApiResult<ProfileMediaUploadResult>> uploadCover(
    String filePath, {
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) {
    return _repository.uploadCover(
      filePath,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  Future<ApiResult<ProfileMediaUploadResult>> removeAvatar() {
    return _repository.removeAvatar();
  }

  Future<ApiResult<ProfileMediaUploadResult>> removeCover() {
    return _repository.removeCover();
  }
}

final profileMediaServiceProvider = Provider<ProfileMediaService>((ref) {
  return ProfileMediaService(ref.watch(profileMediaRepositoryProvider));
});
