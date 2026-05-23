enum UploadKind { image, document, video }

class UploadValidation {
  UploadValidation._();

  static const defaultMaxImageBytes = 5 * 1024 * 1024;
  static const defaultMaxDocumentBytes = 10 * 1024 * 1024;
  static const defaultMaxVideoBytes = 80 * 1024 * 1024;
  static const defaultMaxSupportBytes = 8 * 1024 * 1024;

  static const imageMimes = {'image/jpeg', 'image/png', 'image/webp'};

  static const documentMimes = {
    'application/pdf',
    'image/jpeg',
    'image/png',
    'image/webp',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'text/plain',
  };

  static const videoMimes = {'video/mp4', 'video/webm'};

  static UploadKind? kindForMime(String mimeType) {
    final normalized = mimeType.toLowerCase();
    if (imageMimes.contains(normalized)) return UploadKind.image;
    if (documentMimes.contains(normalized)) return UploadKind.document;
    if (videoMimes.contains(normalized)) return UploadKind.video;
    return null;
  }

  static String? mimeFromPath(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'pdf' => 'application/pdf',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'txt' => 'text/plain',
      'mp4' => 'video/mp4',
      'webm' => 'video/webm',
      _ => null,
    };
  }

  static String? validateFile({
    required String path,
    required int sizeBytes,
    String? mimeType,
    UploadKind? expectedKind,
    int? maxBytes,
  }) {
    final mime = (mimeType ?? mimeFromPath(path) ?? 'application/octet-stream')
        .toLowerCase();
    final kind = kindForMime(mime);
    if (kind == null) {
      return 'Unsupported file type';
    }
    if (expectedKind != null && kind != expectedKind) {
      return 'Unsupported file type for this upload';
    }

    final limit = maxBytes ?? _defaultLimit(kind);
    if (sizeBytes > limit) {
      return 'File exceeds size limit';
    }

    final ext = path.split('.').last.toLowerCase();
    const blocked = {'exe', 'bat', 'cmd', 'sh', 'php', 'js', 'html', 'svg'};
    if (blocked.contains(ext)) {
      return 'This file type is not allowed';
    }

    return null;
  }

  static int _defaultLimit(UploadKind kind) {
    return switch (kind) {
      UploadKind.image => defaultMaxImageBytes,
      UploadKind.document => defaultMaxDocumentBytes,
      UploadKind.video => defaultMaxVideoBytes,
    };
  }
}
