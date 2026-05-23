/// Profile media upload API paths.
abstract final class ProfileMediaApiPaths {
  ProfileMediaApiPaths._();

  static const avatar = '/api/mobile/me/avatar';
  static const cover = '/api/mobile/me/cover';

  /// Profile avatar/cover only — do not use for animal photos.
  static const legacyProfileImage = '/api/mobile/uploads/profile-image';
  static const legacyCoverImage = '/api/mobile/uploads/cover-image';
}

/// Normalized profile media upload response.
class ProfileMediaUploadResult {
  const ProfileMediaUploadResult({
    this.avatarUrl,
    this.avatarThumbUrl,
    this.coverUrl,
    this.coverThumbUrl,
    this.url,
    this.thumbUrl,
    this.mainBytes,
    this.thumbBytes,
    this.originalBytes,
  });

  final String? avatarUrl;
  final String? avatarThumbUrl;
  final String? coverUrl;
  final String? coverThumbUrl;
  final String? url;
  final String? thumbUrl;
  final int? mainBytes;
  final int? thumbBytes;
  final int? originalBytes;

  String? get profileImageUrl => avatarThumbUrl ?? avatarUrl ?? thumbUrl ?? url;
  String? get coverImageUrl => coverThumbUrl ?? coverUrl;

  factory ProfileMediaUploadResult.fromJson(Map<String, dynamic> json) {
    final avatarUrl = _str(
      json,
      'avatarUrl',
      'profileImageUrl',
      'profilePhotoUrl',
    );
    final avatarThumbUrl = _str(
      json,
      'avatarThumbUrl',
      'profileThumbUrl',
      'profilePhotoThumbUrl',
    );
    final coverUrl = _str(json, 'coverUrl', 'coverImageUrl', 'coverPhotoUrl');
    final coverThumbUrl = _str(
      json,
      'coverThumbUrl',
      'coverImageThumbUrl',
      'coverPhotoThumbUrl',
    );
    return ProfileMediaUploadResult(
      avatarUrl: avatarUrl,
      avatarThumbUrl: avatarThumbUrl,
      coverUrl: coverUrl,
      coverThumbUrl: coverThumbUrl,
      url: json['url'] as String? ?? avatarUrl ?? coverUrl,
      thumbUrl:
          json['thumbUrl'] as String? ??
          json['thumb'] as String? ??
          avatarThumbUrl ??
          coverThumbUrl,
      mainBytes: json['mainBytes'] as int?,
      thumbBytes: json['thumbBytes'] as int?,
    );
  }
}

String? _str(
  Map<String, dynamic> json,
  String primary,
  String alias,
  String legacy,
) {
  final v = json[primary] ?? json[alias] ?? json[legacy];
  if (v is String && v.isNotEmpty) return v;
  return null;
}

/// Client-side compression stats shown in crop confirm UI.
class ProfileCompressionStats {
  const ProfileCompressionStats({
    required this.originalBytes,
    required this.optimizedBytes,
    required this.outputPath,
  });

  final int originalBytes;
  final int optimizedBytes;
  final String outputPath;

  String get label {
    final from = _formatBytes(originalBytes);
    final to = _formatBytes(optimizedBytes);
    return 'Optimized: $from → $to';
  }

  static String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / 1024).round()}KB';
  }
}

enum ProfileMediaKind { avatar, cover }

enum ProfileMediaUploadState { idle, uploading, success, error }
