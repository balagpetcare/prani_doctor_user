class ProviderPaginationDto {
  const ProviderPaginationDto({
    required this.limit,
    required this.offset,
    required this.total,
    required this.hasMore,
  });

  final int limit;
  final int offset;
  final int total;
  final bool hasMore;

  factory ProviderPaginationDto.fromJson(Map<String, dynamic> json) {
    return ProviderPaginationDto(
      limit: json['limit'] as int? ?? 20,
      offset: json['offset'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}

class ProviderDoctorListItemDto {
  const ProviderDoctorListItemDto({
    required this.id,
    required this.name,
    this.degreeOrQualification,
    required this.serviceType,
    required this.areaText,
    this.fee,
    required this.availability,
    required this.homeVisit,
    required this.emergency,
    required this.onlineConsultation,
    this.profilePhotoUrl,
  });

  final String id;
  final String name;
  final String? degreeOrQualification;
  final String serviceType;
  final String areaText;
  final String? fee;
  final String availability;
  final bool homeVisit;
  final bool emergency;
  final bool onlineConsultation;
  final String? profilePhotoUrl;

  factory ProviderDoctorListItemDto.fromJson(Map<String, dynamic> json) {
    return ProviderDoctorListItemDto(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      degreeOrQualification: json['degreeOrQualification'] as String?,
      serviceType: json['serviceType'] as String? ?? '',
      areaText: json['areaText'] as String? ?? '',
      fee: json['fee'] as String?,
      availability: json['availability'] as String? ?? '',
      homeVisit: json['homeVisit'] as bool? ?? false,
      emergency: json['emergency'] as bool? ?? false,
      onlineConsultation: json['onlineConsultation'] as bool? ?? false,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
    );
  }
}

class ProviderDoctorDetailDto extends ProviderDoctorListItemDto {
  const ProviderDoctorDetailDto({
    required super.id,
    required super.name,
    super.degreeOrQualification,
    required super.serviceType,
    required super.areaText,
    super.fee,
    required super.availability,
    required super.homeVisit,
    required super.emergency,
    required super.onlineConsultation,
    super.profilePhotoUrl,
    this.bio,
    this.experienceYears,
    this.areas = const [],
    this.villages = const [],
    this.serviceCategories = const [],
  });

  final String? bio;
  final int? experienceYears;
  final List<ProviderAreaLinkDto> areas;
  final List<ProviderVillageLinkDto> villages;
  final List<ProviderCategoryLinkDto> serviceCategories;

  factory ProviderDoctorDetailDto.fromJson(Map<String, dynamic> json) {
    return ProviderDoctorDetailDto(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      degreeOrQualification: json['degreeOrQualification'] as String?,
      serviceType: json['serviceType'] as String? ?? '',
      areaText: json['areaText'] as String? ?? '',
      fee: json['fee'] as String?,
      availability: json['availability'] as String? ?? '',
      homeVisit: json['homeVisit'] as bool? ?? false,
      emergency: json['emergency'] as bool? ?? false,
      onlineConsultation: json['onlineConsultation'] as bool? ?? false,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      bio: json['bio'] as String?,
      experienceYears: json['experienceYears'] as int?,
      areas: (json['areas'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ProviderAreaLinkDto.fromJson)
          .toList(),
      villages: (json['villages'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ProviderVillageLinkDto.fromJson)
          .toList(),
      serviceCategories: (json['serviceCategories'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ProviderCategoryLinkDto.fromJson)
          .toList(),
    );
  }
}

class ProviderAreaLinkDto {
  const ProviderAreaLinkDto({
    required this.id,
    required this.name,
    this.nameBn,
    required this.slug,
    required this.type,
  });

  final String id;
  final String name;
  final String? nameBn;
  final String slug;
  final String type;

  factory ProviderAreaLinkDto.fromJson(Map<String, dynamic> json) {
    return ProviderAreaLinkDto(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      nameBn: json['nameBn'] as String?,
      slug: json['slug'] as String? ?? '',
      type: json['type'] as String? ?? '',
    );
  }
}

class ProviderVillageLinkDto {
  const ProviderVillageLinkDto({
    required this.id,
    required this.name,
    required this.slug,
  });

  final String id;
  final String name;
  final String slug;

  factory ProviderVillageLinkDto.fromJson(Map<String, dynamic> json) {
    return ProviderVillageLinkDto(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
    );
  }
}

class ProviderCategoryLinkDto {
  const ProviderCategoryLinkDto({
    required this.id,
    required this.name,
    required this.slug,
  });

  final String id;
  final String name;
  final String slug;

  factory ProviderCategoryLinkDto.fromJson(Map<String, dynamic> json) {
    return ProviderCategoryLinkDto(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
    );
  }
}

class DoctorListResultDto {
  const DoctorListResultDto({required this.doctors, required this.pagination});

  final List<ProviderDoctorListItemDto> doctors;
  final ProviderPaginationDto pagination;
}

class ServiceCategoryDto {
  const ServiceCategoryDto({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
  });

  final String id;
  final String name;
  final String slug;
  final String? description;

  factory ServiceCategoryDto.fromJson(Map<String, dynamic> json) {
    return ServiceCategoryDto(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
    );
  }
}

class AnimalProfileDto {
  const AnimalProfileDto({
    required this.id,
    required this.name,
    required this.animalType,
    this.species,
  });

  final String id;
  final String name;
  final String animalType;
  final String? species;

  factory AnimalProfileDto.fromJson(Map<String, dynamic> json) {
    return AnimalProfileDto(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['tag'] as String? ?? 'Animal',
      animalType: json['animalType'] as String? ?? '',
      species: json['species'] as String?,
    );
  }
}
