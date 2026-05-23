const _unset = Object();

class MobileMeAddressDto {
  const MobileMeAddressDto({
    this.divisionId,
    this.districtId,
    this.upazilaId,
    this.unionId,
    this.villageId,
    this.villageName,
    this.line1,
    this.postalCode,
  });

  final String? divisionId;
  final String? districtId;
  final String? upazilaId;
  final String? unionId;
  final String? villageId;

  /// Free-text village when not in master data (sent as `villageName` to API).
  final String? villageName;
  final String? line1;
  final String? postalCode;

  factory MobileMeAddressDto.fromJson(Map<String, dynamic> json) {
    return MobileMeAddressDto(
      divisionId: json['divisionId'] as String?,
      districtId: json['districtId'] as String?,
      upazilaId: json['upazilaId'] as String?,
      unionId: json['unionId'] as String?,
      villageId: json['villageId'] as String?,
      villageName:
          json['villageName'] as String? ?? json['villageNameBn'] as String?,
      line1: json['line1'] as String?,
      postalCode: json['postalCode'] as String?,
    );
  }

  Map<String, dynamic> toPatchJson() {
    return {
      if (divisionId != null) 'divisionId': divisionId,
      if (districtId != null) 'districtId': districtId,
      if (upazilaId != null) 'upazilaId': upazilaId,
      if (unionId != null) 'unionId': unionId,
      if (villageId != null) 'villageId': villageId,
      if (villageName != null && villageName!.trim().isNotEmpty)
        'villageName': villageName!.trim(),
      if (line1 != null) 'line1': line1,
      if (postalCode != null) 'postalCode': postalCode,
    };
  }

  Map<String, dynamic> toJson() => toPatchJson();
}

class MobileMeDto {
  const MobileMeDto({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.area,
    required this.locale,
    required this.role,
    this.profilePhotoUrl,
    this.profilePhotoThumbUrl,
    this.coverPhotoUrl,
    this.coverPhotoThumbUrl,
    this.profileComplete,
    this.address,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final String? area;
  final String locale;
  final String role;
  final String? profilePhotoUrl;
  final String? profilePhotoThumbUrl;
  final String? coverPhotoUrl;
  final String? coverPhotoThumbUrl;
  final bool? profileComplete;
  final MobileMeAddressDto? address;

  /// Preferred display URL (thumb when available).
  String? get profileImageUrl => profilePhotoThumbUrl ?? profilePhotoUrl;
  String? get coverImageUrl => coverPhotoThumbUrl ?? coverPhotoUrl;

  bool get hasDisplayName => name.trim().isNotEmpty;

  /// Union is required for onboarding; village is optional.
  bool get hasRequiredLocation => address?.unionId?.isNotEmpty ?? false;

  bool get hasLocation => hasRequiredLocation;

  /// Client-side completion — name + union. Photo/village never block navigation.
  bool get canContinueToHome => hasDisplayName && hasRequiredLocation;

  bool get needsProfileSetup => !canContinueToHome;

  factory MobileMeDto.fromJson(Map<String, dynamic> json) {
    MobileMeAddressDto? address;
    final rawAddress = json['address'];
    if (rawAddress is Map<String, dynamic>) {
      address = MobileMeAddressDto.fromJson(rawAddress);
    }

    return MobileMeDto(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      area: json['area'] as String?,
      locale: json['locale'] as String? ?? 'bn-BD',
      role: json['role'] as String? ?? 'customer',
      profilePhotoUrl: _str(
        json,
        'profilePhotoUrl',
        'profileImageUrl',
        'avatarUrl',
      ),
      profilePhotoThumbUrl: _str(
        json,
        'profilePhotoThumbUrl',
        'profileImageThumbUrl',
        'avatarThumbUrl',
      ),
      coverPhotoUrl: _str(json, 'coverPhotoUrl', 'coverImageUrl', 'coverUrl'),
      coverPhotoThumbUrl: _str(
        json,
        'coverPhotoThumbUrl',
        'coverImageThumbUrl',
        'coverThumbUrl',
      ),
      profileComplete: json['profileComplete'] as bool?,
      address: address,
    );
  }

  MobileMeDto copyWith({
    String? name,
    String? email,
    String? area,
    String? locale,
    Object? profilePhotoUrl = _unset,
    Object? profilePhotoThumbUrl = _unset,
    Object? coverPhotoUrl = _unset,
    Object? coverPhotoThumbUrl = _unset,
    bool? profileComplete,
    MobileMeAddressDto? address,
  }) {
    return MobileMeDto(
      id: id,
      name: name ?? this.name,
      phone: phone,
      email: email ?? this.email,
      area: area ?? this.area,
      locale: locale ?? this.locale,
      role: role,
      profilePhotoUrl: profilePhotoUrl == _unset
          ? this.profilePhotoUrl
          : profilePhotoUrl as String?,
      profilePhotoThumbUrl: profilePhotoThumbUrl == _unset
          ? this.profilePhotoThumbUrl
          : profilePhotoThumbUrl as String?,
      coverPhotoUrl: coverPhotoUrl == _unset
          ? this.coverPhotoUrl
          : coverPhotoUrl as String?,
      coverPhotoThumbUrl: coverPhotoThumbUrl == _unset
          ? this.coverPhotoThumbUrl
          : coverPhotoThumbUrl as String?,
      profileComplete: profileComplete ?? this.profileComplete,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    if (area != null) 'area': area,
    'locale': locale,
    'role': role,
    if (profilePhotoUrl != null) 'profilePhotoUrl': profilePhotoUrl,
    if (profilePhotoThumbUrl != null)
      'profilePhotoThumbUrl': profilePhotoThumbUrl,
    if (coverPhotoUrl != null) 'coverPhotoUrl': coverPhotoUrl,
    if (coverPhotoThumbUrl != null) 'coverPhotoThumbUrl': coverPhotoThumbUrl,
    if (profileComplete != null) 'profileComplete': profileComplete,
    if (address != null) 'address': address!.toJson(),
  };

  MobileMeDto mergeAddress(MobileMeAddressDto? cachedAddress) {
    if (address != null || cachedAddress == null) return this;
    return copyWith(address: cachedAddress);
  }
}

class PatchMobileMeInput {
  const PatchMobileMeInput({
    this.name,
    this.email,
    this.area,
    this.locale,
    this.address,
  });

  final String? name;
  final String? email;
  final String? area;
  final String? locale;
  final MobileMeAddressDto? address;

  bool get hasPayload => toJson().isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (area != null) 'area': area,
      if (locale != null) 'locale': locale,
      if (address != null) 'address': address!.toPatchJson(),
    };
  }
}

String? _str(
  Map<String, dynamic> json,
  String primary,
  String alias, [
  String? alias2,
]) {
  final v =
      json[primary] ?? json[alias] ?? (alias2 != null ? json[alias2] : null);
  if (v is String && v.isNotEmpty) return v;
  return null;
}
