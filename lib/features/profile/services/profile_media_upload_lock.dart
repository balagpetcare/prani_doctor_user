import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/profile_media_models.dart';

/// Ensures only one profile media upload runs per kind at a time.
final class ProfileMediaUploadLock {
  ProfileMediaUploadLock._();
  static final ProfileMediaUploadLock instance = ProfileMediaUploadLock._();

  CancelToken? _avatarToken;
  CancelToken? _coverToken;
  bool _avatarBusy = false;
  bool _coverBusy = false;

  bool isUploading(ProfileMediaKind kind) =>
      kind == ProfileMediaKind.avatar ? _avatarBusy : _coverBusy;

  /// Returns a cancel token when acquired; null if already uploading.
  CancelToken? acquire(ProfileMediaKind kind) {
    if (isUploading(kind)) {
      if (kDebugMode) {
        debugPrint('[MEDIA_LOCK] ${kind.name} busy — tap ignored');
      }
      return null;
    }

    final previous = kind == ProfileMediaKind.avatar
        ? _avatarToken
        : _coverToken;
    previous?.cancel('superseded');

    final token = CancelToken();
    if (kind == ProfileMediaKind.avatar) {
      _avatarBusy = true;
      _avatarToken = token;
    } else {
      _coverBusy = true;
      _coverToken = token;
    }
    if (kDebugMode) debugPrint('[MEDIA_LOCK] ${kind.name} acquired');
    return token;
  }

  void release(ProfileMediaKind kind) {
    if (kind == ProfileMediaKind.avatar) {
      _avatarBusy = false;
      _avatarToken = null;
    } else {
      _coverBusy = false;
      _coverToken = null;
    }
    if (kDebugMode) debugPrint('[MEDIA_LOCK] ${kind.name} released');
  }
}
