import '../../profile/data/mobile_me_dto.dart';
import 'farm_location.dart';

enum FarmFilter { all, hasAnimals, needsLocation }

enum FarmSort { nameAsc, nameDesc, animalsDesc }

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

  bool get hasLocation {
    final loc = FarmLocation.fromAddress(address);
    return loc.canSaveFarm;
  }

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
    final location = FarmLocation.fromAddress(
      profile.address,
      areaLabel: profile.area,
    );
    if (!location.canSaveFarm) return null;

    final resolvedVillageId = location.villageId ?? location.locationKey;
    final villageDisplay = location.villageName?.trim().isNotEmpty == true
        ? location.villageName!.trim()
        : villageLabel?.trim();
    final label = location.fullAddress?.isNotEmpty == true
        ? location.fullAddress!
        : (villageDisplay?.isNotEmpty == true
              ? villageDisplay!
              : (profile.area?.trim().isNotEmpty == true
                    ? profile.area!.trim()
                    : profile.name));

    final locationLabel = [
      if (villageDisplay != null && villageDisplay.isNotEmpty) villageDisplay,
      if (profile.area?.trim().isNotEmpty == true) profile.area!.trim(),
    ].join(', ').trim().isEmpty
        ? label
        : [
            if (villageDisplay != null && villageDisplay.isNotEmpty)
              villageDisplay,
            if (profile.area?.trim().isNotEmpty == true) profile.area!.trim(),
          ].join(', ');

    final farmName = () {
      final area = profile.area?.trim();
      if (area != null && area.isNotEmpty) return area;
      if (profile.name.trim().isNotEmpty) return profile.name.trim();
      return label;
    }();

    return Farm(
      id: location.farmIdFor(),
      name: farmName,
      locationLabel: locationLabel,
      villageId: resolvedVillageId,
      animalCount: animalCount,
      activeAnimalCount: activeAnimalCount,
      coverPhotoUrl: profile.coverPhotoUrl,
      address: location.toAddressDto(),
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
    this.coverPhotoUrl,
  });

  final String name;
  final MobileMeAddressDto address;
  final String? areaLabel;
  final String? coverPhotoUrl;

  PatchMobileMeInput toPatchInput({MobileMeDto? existingProfile}) {
    final existingAddress = existingProfile?.address;
    final mergedAddress = address.mergeForPatch(existingAddress);
    final resolvedArea = () {
      final label = areaLabel?.trim();
      if (label != null && label.isNotEmpty) return label;
      final existingArea = existingProfile?.area?.trim();
      if (existingArea != null && existingArea.isNotEmpty) return existingArea;
      return null;
    }();
    return PatchMobileMeInput(area: resolvedArea, address: mergedAddress);
  }

  Map<String, dynamic> toDraftJson() => {
    'name': name,
    'areaLabel': areaLabel,
    if (coverPhotoUrl != null) 'coverPhotoUrl': coverPhotoUrl,
    'address': address.toJson(),
    'location': FarmLocation.fromAddress(address, areaLabel: areaLabel).toJson(),
  };

  factory FarmInput.fromDraftJson(Map<String, dynamic> json) {
    MobileMeAddressDto? address;
    final rawAddress = json['address'];
    if (rawAddress is Map<String, dynamic>) {
      address = MobileMeAddressDto.fromJson(rawAddress);
    }
    final rawLocation = json['location'];
    if (address == null && rawLocation is Map<String, dynamic>) {
      address = FarmLocation.fromJson(rawLocation).toAddressDto();
    }
    return FarmInput(
      name: json['name'] as String? ?? '',
      areaLabel: json['areaLabel'] as String? ??
          (rawLocation is Map<String, dynamic>
              ? rawLocation['displayAddress'] as String?
              : null),
      coverPhotoUrl: json['coverPhotoUrl'] as String?,
      address: address ?? const MobileMeAddressDto(),
    );
  }
}
