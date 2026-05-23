/// Bangladesh area hierarchy DTO — mirrors GET /api/mobile/locations/* responses.
class AreaNodeDto {
  const AreaNodeDto({
    required this.id,
    required this.slug,
    required this.code,
    required this.nameBn,
    required this.nameEn,
    required this.label,
    required this.level,
    this.parentId,
    this.latitude,
    this.longitude,
    required this.isVerified,
  });

  final String id;
  final String slug;
  final String? code;
  final String nameBn;
  final String nameEn;
  final String label;
  final String level;
  final String? parentId;
  final double? latitude;
  final double? longitude;
  final bool isVerified;

  factory AreaNodeDto.fromJson(Map<String, dynamic> json) {
    return AreaNodeDto(
      id: json['id'] as String,
      slug: json['slug'] as String,
      code: json['code'] as String?,
      nameBn: json['nameBn'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      label: json['label'] as String? ?? '',
      level: json['level'] as String,
      parentId: json['parentId'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  /// Maps mobile location rows (`MobileLocationDto`) plus caller context.
  factory AreaNodeDto.fromMobileJson(
    Map<String, dynamic> json, {
    required String level,
    String? parentId,
    String locale = 'bn',
  }) {
    final nameBn = json['nameBn'] as String? ?? '';
    final nameEn = json['nameEn'] as String? ?? '';
    final label = locale == 'en' && nameEn.isNotEmpty ? nameEn : nameBn;
    return AreaNodeDto(
      id: json['id'] as String,
      slug: json['slug'] as String? ?? json['id'] as String,
      code: json['code'] as String?,
      nameBn: nameBn,
      nameEn: nameEn,
      label: label.isNotEmpty ? label : (nameBn.isNotEmpty ? nameBn : nameEn),
      level: level,
      parentId: parentId,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }
}

class AreaSearchHitDto extends AreaNodeDto {
  const AreaSearchHitDto({
    required super.id,
    required super.slug,
    required super.code,
    required super.nameBn,
    required super.nameEn,
    required super.label,
    required super.level,
    super.parentId,
    super.latitude,
    super.longitude,
    required super.isVerified,
    this.breadcrumb,
  });

  final String? breadcrumb;

  factory AreaSearchHitDto.fromJson(Map<String, dynamic> json) {
    return AreaSearchHitDto(
      id: json['id'] as String,
      slug: json['slug'] as String,
      code: json['code'] as String?,
      nameBn: json['nameBn'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      label: json['label'] as String? ?? '',
      level: json['level'] as String,
      parentId: json['parentId'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isVerified: json['isVerified'] as bool? ?? false,
      breadcrumb: json['breadcrumb'] as String?,
    );
  }

  factory AreaSearchHitDto.fromMobileJson(
    Map<String, dynamic> json, {
    String locale = 'bn',
  }) {
    final level = json['level'] as String? ?? 'VILLAGE';
    final node = AreaNodeDto.fromMobileJson(json, level: level, locale: locale);
    return AreaSearchHitDto(
      id: node.id,
      slug: node.slug,
      code: node.code,
      nameBn: node.nameBn,
      nameEn: node.nameEn,
      label: node.label,
      level: node.level,
      parentId: node.parentId,
      latitude: node.latitude,
      longitude: node.longitude,
      isVerified: node.isVerified,
      breadcrumb: json['breadcrumb'] as String?,
    );
  }
}

class AreaPageMeta {
  const AreaPageMeta({
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  factory AreaPageMeta.fromJson(Map<String, dynamic> json) {
    return AreaPageMeta(
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}

class AreaPage<T> {
  const AreaPage({
    required this.data,
    required this.meta,
    this.fromCache = false,
  });

  final List<T> data;
  final AreaPageMeta meta;
  final bool fromCache;
}
