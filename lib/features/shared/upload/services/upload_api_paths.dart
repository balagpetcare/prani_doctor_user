/// Mobile upload API paths (MinIO-backed via backend).
abstract final class UploadApiPaths {
  UploadApiPaths._();

  static const upload = '/api/mobile/upload';
  static const uploadMultiple = '/api/mobile/upload/multiple';
  static const presigned = '/api/mobile/upload/presigned';

  static String delete(String fileId) => '/api/mobile/upload/$fileId';

  /// Legacy dedicated routes (still supported).
  static const profileImage = '/api/mobile/uploads/profile-image';
  static const coverImage = '/api/mobile/uploads/cover-image';
  static const supportUpload = '/api/mobile/support/upload';

  static String downloadById(String fileId) => '/api/mobile/uploads/$fileId';
}
