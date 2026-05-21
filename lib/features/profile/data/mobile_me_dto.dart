class MobileMeAddressDto {
  const MobileMeAddressDto({
    this.divisionId,
    this.districtId,
    this.upazilaId,
    this.unionId,
    this.villageId,
    this.line1,
    this.postalCode,
  });

  final String? divisionId;
  final String? districtId;
  final String? upazilaId;
  final String? unionId;
  final String? villageId;
  final String? line1;
  final String? postalCode;

  Map<String, dynamic> toPatchJson() {
    return {
      if (divisionId != null) 'divisionId': divisionId,
      if (districtId != null) 'districtId': districtId,
      if (upazilaId != null) 'upazilaId': upazilaId,
      if (unionId != null) 'unionId': unionId,
      if (villageId != null) 'villageId': villageId,
      if (line1 != null) 'line1': line1,
      if (postalCode != null) 'postalCode': postalCode,
    };
  }
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
    this.coverPhotoUrl,
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
  final String? coverPhotoUrl;
  final bool? profileComplete;
  final MobileMeAddressDto? address;

  factory MobileMeDto.fromJson(Map<String, dynamic> json) {
    MobileMeAddressDto? address;
    final rawAddress = json['address'];
    if (rawAddress is Map<String, dynamic>) {
      address = MobileMeAddressDto(
        divisionId: rawAddress['divisionId'] as String?,
        districtId: rawAddress['districtId'] as String?,
        upazilaId: rawAddress['upazilaId'] as String?,
        unionId: rawAddress['unionId'] as String?,
        villageId: rawAddress['villageId'] as String?,
        line1: rawAddress['line1'] as String?,
        postalCode: rawAddress['postalCode'] as String?,
      );
    }

    return MobileMeDto(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      area: json['area'] as String?,
      locale: json['locale'] as String? ?? 'bn-BD',
      role: json['role'] as String? ?? 'customer',
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      coverPhotoUrl: json['coverPhotoUrl'] as String?,
      profileComplete: json['profileComplete'] as bool?,
      address: address,
    );
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
