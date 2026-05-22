import '../../profile/data/mobile_me_dto.dart';

enum FarmFilter { all, hasAnimals, needsLocation }

class Farm {
  const Farm({
    required this.id,
    required this.name,
    required this.locationLabel,
    this.villageId,
    required this.animalCount,
    required this.activeAnimalCount,
    this.coverPhotoUrl,
    this.address,
    this.fromCache = false,
  });

  final String id;
  final String name;
  final String locationLabel;
  final String? villageId;
  final int animalCount;
  final int activeAnimalCount;
  final String? coverPhotoUrl;
  final MobileMeAddressDto? address;
  final bool fromCache;

  bool get hasLocation => villageId != null && villageId!.isNotEmpty;

  List<String> get imageUrls {
    final urls = <String>[];
    if (coverPhotoUrl != null && coverPhotoUrl!.isNotEmpty) {
      urls.add(coverPhotoUrl!);
    }
    return urls;
  }

  Farm copyWith({
    String? name,
    String? locationLabel,
    String? villageId,
    int? animalCount,
    int? activeAnimalCount,
    String? coverPhotoUrl,
    MobileMeAddressDto? address,
    bool? fromCache,
  }) {
    return Farm(
      id: id,
      name: name ?? this.name,
      locationLabel: locationLabel ?? this.locationLabel,
      villageId: villageId ?? this.villageId,
      animalCount: animalCount ?? this.animalCount,
      activeAnimalCount: activeAnimalCount ?? this.activeAnimalCount,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      address: address ?? this.address,
      fromCache: fromCache ?? this.fromCache,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'locationLabel': locationLabel,
        if (villageId != null) 'villageId': villageId,
        'animalCount': animalCount,
        'activeAnimalCount': activeAnimalCount,
        if (coverPhotoUrl != null) 'coverPhotoUrl': coverPhotoUrl,
        if (address != null) 'address': address!.toJson(),
        'fromCache': fromCache,
      };

  factory Farm.fromJson(Map<String, dynamic> json) {
    MobileMeAddressDto? address;
    final rawAddress = json['address'];
    if (rawAddress is Map<String, dynamic>) {
      address = MobileMeAddressDto.fromJson(rawAddress);
    }
    return Farm(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      locationLabel: json['locationLabel'] as String? ?? '',
      villageId: json['villageId'] as String?,
      animalCount: json['animalCount'] as int? ?? 0,
      activeAnimalCount: json['activeAnimalCount'] as int? ?? 0,
      coverPhotoUrl: json['coverPhotoUrl'] as String?,
      address: address,
      fromCache: json['fromCache'] as bool? ?? false,
    );
  }

  static Farm? fromProfile({
    required MobileMeDto profile,
    int animalCount = 0,
    int activeAnimalCount = 0,
    String? villageLabel,
    bool fromCache = false,
  }) {
    final villageId = profile.address?.villageId;
    if (villageId == null || villageId.isEmpty) return null;

    final label = profile.area?.trim().isNotEmpty == true
        ? profile.area!.trim()
        : (villageLabel?.trim().isNotEmpty == true
            ? villageLabel!.trim()
            : profile.name);

    return Farm(
      id: 'farm-$villageId',
      name: label,
      locationLabel: profile.area ?? villageLabel ?? label,
      villageId: villageId,
      animalCount: animalCount,
      activeAnimalCount: activeAnimalCount,
      coverPhotoUrl: profile.coverPhotoUrl,
      address: profile.address,
      fromCache: fromCache,
    );
  }
}

class FarmPageResult {
  const FarmPageResult({
    required this.farms,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
    this.fromCache = false,
  });

  final List<Farm> farms;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;
  final bool fromCache;

  static const empty = FarmPageResult(
    farms: [],
    total: 0,
    page: 1,
    pageSize: 20,
    hasMore: false,
  );
}

class FarmDetail {
  const FarmDetail({
    required this.farm,
    required this.animals,
    this.fromCache = false,
  });

  final Farm farm;
  final List<FarmAnimalSummary> animals;
  final bool fromCache;
}

class FarmAnimalSummary {
  const FarmAnimalSummary({
    required this.id,
    required this.name,
    required this.animalType,
    this.photoUrl,
  });

  final String id;
  final String name;
  final String animalType;
  final String? photoUrl;

  factory FarmAnimalSummary.fromJson(Map<String, dynamic> json) {
    return FarmAnimalSummary(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['tag'] as String? ?? 'Animal',
      animalType: json['animalType'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
    );
  }
}

class FarmInput {
  const FarmInput({
    required this.name,
    required this.address,
    this.areaLabel,
  });

  final String name;
  final MobileMeAddressDto address;
  final String? areaLabel;

  PatchMobileMeInput toPatchInput() {
    return PatchMobileMeInput(
      area: areaLabel ?? name,
      address: address,
    );
  }
}
