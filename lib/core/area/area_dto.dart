/// Bangladesh area hierarchy DTO — mirrors GET /api/area/* foundation responses.
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
  const AreaPage({required this.data, required this.meta});

  final List<T> data;
  final AreaPageMeta meta;
}
