class UploadResult {
  const UploadResult({
    required this.fileId,
    required this.url,
    required this.objectKey,
    required this.mimeType,
    required this.sizeBytes,
    required this.bucket,
    this.originalName,
    this.profilePhotoUrl,
    this.coverPhotoUrl,
    this.localPath,
  });

  final String fileId;
  final String url;
  final String objectKey;
  final String mimeType;
  final int sizeBytes;
  final String bucket;
  final String? originalName;
  final String? profilePhotoUrl;
  final String? coverPhotoUrl;
  final String? localPath;

  /// URL for animal photos — never reads profile avatar fields.
  String get animalPhotoUrl => url;

  /// URL for user profile avatar — never reads animal/generic file URLs alone.
  String get userProfilePhotoUrl =>
      profilePhotoUrl ?? coverPhotoUrl ?? '';

  factory UploadResult.fromJson(
    Map<String, dynamic> json, {
    String? localPath,
  }) {
    final sizeRaw = json['size'] ?? json['sizeBytes'];
    final sizeBytes = switch (sizeRaw) {
      int value => value,
      String value => int.tryParse(value) ?? 0,
      _ => 0,
    };

    final url =
        json['url'] as String? ??
        json['downloadUrl'] as String? ??
        json['profilePhotoUrl'] as String? ??
        json['coverPhotoUrl'] as String? ??
        '';

    return UploadResult(
      fileId: json['fileId'] as String? ?? '',
      url: url,
      objectKey:
          json['objectKey'] as String? ?? json['storageKey'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
      sizeBytes: sizeBytes,
      bucket: json['bucket'] as String? ?? '',
      originalName: json['originalName'] as String?,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      coverPhotoUrl: json['coverPhotoUrl'] as String?,
      localPath: localPath,
    );
  }
}

enum UploadTaskState { idle, validating, uploading, success, error, cancelled }

class UploadTask {
  const UploadTask({
    required this.localPath,
    this.fileName,
    this.mimeType,
    this.sizeBytes = 0,
    this.state = UploadTaskState.idle,
    this.progress = 0,
    this.errorMessage,
    this.result,
    this.cancelToken,
  });

  final String localPath;
  final String? fileName;
  final String? mimeType;
  final int sizeBytes;
  final UploadTaskState state;
  final double progress;
  final String? errorMessage;
  final UploadResult? result;
  final Object? cancelToken;

  bool get isComplete => state == UploadTaskState.success && result != null;

  UploadTask copyWith({
    String? localPath,
    String? fileName,
    String? mimeType,
    int? sizeBytes,
    UploadTaskState? state,
    double? progress,
    String? errorMessage,
    UploadResult? result,
    Object? cancelToken,
  }) {
    return UploadTask(
      localPath: localPath ?? this.localPath,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      state: state ?? this.state,
      progress: progress ?? this.progress,
      errorMessage: errorMessage,
      result: result ?? this.result,
      cancelToken: cancelToken ?? this.cancelToken,
    );
  }
}
