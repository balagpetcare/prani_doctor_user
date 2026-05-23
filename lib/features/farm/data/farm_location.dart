import '../../profile/data/mobile_me_dto.dart';

/// Normalized farm/profile location with IDs + labels for persistence and restore.
class FarmLocation {
  const FarmLocation({
    this.divisionId,
    this.districtId,
    this.upazilaId,
    this.unionId,
    this.villageId,
    this.villageName,
    this.displayAddress,
  });

  final String? divisionId;
  final String? districtId;
  final String? upazilaId;
  final String? unionId;
  final String? villageId;
  final String? villageName;
  final String? displayAddress;

  bool get hasHierarchy =>
      _nonEmpty(divisionId) &&
      _nonEmpty(districtId) &&
      _nonEmpty(upazilaId) &&
      _nonEmpty(unionId);

  /// Union is required; village is optional (id or free-text name).
  bool get canSaveFarm => hasHierarchy;

  bool get hasVillageSelection =>
      _nonEmpty(villageId) || _nonEmpty(villageName);

  String? get fullAddress {
    if (displayAddress != null && displayAddress!.trim().isNotEmpty) {
      return displayAddress!.trim();
    }
    if (villageName != null && villageName!.trim().isNotEmpty) {
      return villageName!.trim();
    }
    return null;
  }

  /// Stable farm key — prefer village id, fall back to union.
  String? get locationKey {
    if (_nonEmpty(villageId)) return villageId;
    if (_nonEmpty(unionId)) return 'union:$unionId';
    return null;
  }

  String farmIdFor({String? existingFarmId}) {
    if (existingFarmId != null && existingFarmId.isNotEmpty) {
      return existingFarmId;
    }
    final key = locationKey;
    if (key == null) return 'farm-unknown';
    return 'farm-$key';
  }

  FarmLocation copyWith({
    String? divisionId,
    String? districtId,
    String? upazilaId,
    String? unionId,
    String? villageId,
    String? villageName,
    String? displayAddress,
  }) {
    return FarmLocation(
      divisionId: divisionId ?? this.divisionId,
      districtId: districtId ?? this.districtId,
      upazilaId: upazilaId ?? this.upazilaId,
      unionId: unionId ?? this.unionId,
      villageId: villageId ?? this.villageId,
      villageName: villageName ?? this.villageName,
      displayAddress: displayAddress ?? this.displayAddress,
    );
  }

  MobileMeAddressDto toAddressDto() {
    return MobileMeAddressDto(
      divisionId: divisionId,
      districtId: districtId,
      upazilaId: upazilaId,
      unionId: unionId,
      villageId: villageId,
      villageName: _nonEmpty(villageName) ? villageName!.trim() : null,
    );
  }

  Map<String, dynamic> toJson() => {
    if (divisionId != null) 'divisionId': divisionId,
    if (districtId != null) 'districtId': districtId,
    if (upazilaId != null) 'upazilaId': upazilaId,
    if (unionId != null) 'unionId': unionId,
    if (villageId != null) 'villageId': villageId,
    if (villageName != null) 'villageName': villageName,
    if (displayAddress != null) 'displayAddress': displayAddress,
  };

  factory FarmLocation.fromJson(Map<String, dynamic> json) {
    return FarmLocation(
      divisionId: json['divisionId'] as String?,
      districtId: json['districtId'] as String?,
      upazilaId: json['upazilaId'] as String?,
      unionId: json['unionId'] as String?,
      villageId: json['villageId'] as String?,
      villageName: json['villageName'] as String?,
      displayAddress:
          json['displayAddress'] as String? ?? json['areaLabel'] as String?,
    );
  }

  factory FarmLocation.fromAddress(
    MobileMeAddressDto? address, {
    String? areaLabel,
  }) {
    if (address == null) return const FarmLocation();
    return FarmLocation(
      divisionId: address.divisionId,
      districtId: address.districtId,
      upazilaId: address.upazilaId,
      unionId: address.unionId,
      villageId: address.villageId,
      villageName: address.villageName,
      displayAddress: areaLabel,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FarmLocation &&
        other.divisionId == divisionId &&
        other.districtId == districtId &&
        other.upazilaId == upazilaId &&
        other.unionId == unionId &&
        other.villageId == villageId &&
        other.villageName == villageName &&
        other.displayAddress == displayAddress;
  }

  @override
  int get hashCode => Object.hash(
    divisionId,
    districtId,
    upazilaId,
    unionId,
    villageId,
    villageName,
    displayAddress,
  );

  static bool _nonEmpty(String? value) =>
      value != null && value.trim().isNotEmpty;
}
