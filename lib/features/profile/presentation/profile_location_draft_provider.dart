import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/offline/local_cache_contract.dart';
import '../../offline/data/local_cache_service.dart';
import '../../offline/offline_providers.dart';
import '../data/mobile_me_dto.dart';

const _locationDraftKey = 'profile_location_draft';

/// Locally persisted location selection — survives navigation and app restart.
class ProfileLocationDraft {
  const ProfileLocationDraft({
    this.divisionId,
    this.districtId,
    this.upazilaId,
    this.unionId,
    this.villageId,
    this.villageName,
    this.areaLabel,
    this.line1,
    this.postalCode,
  });

  final String? divisionId;
  final String? districtId;
  final String? upazilaId;
  final String? unionId;
  final String? villageId;
  final String? villageName;
  final String? areaLabel;
  final String? line1;
  final String? postalCode;

  bool get hasUnion => unionId != null && unionId!.isNotEmpty;

  ProfileLocationDraft copyWith({
    String? divisionId,
    String? districtId,
    String? upazilaId,
    String? unionId,
    String? villageId,
    String? villageName,
    String? areaLabel,
    String? line1,
    String? postalCode,
  }) {
    return ProfileLocationDraft(
      divisionId: divisionId ?? this.divisionId,
      districtId: districtId ?? this.districtId,
      upazilaId: upazilaId ?? this.upazilaId,
      unionId: unionId ?? this.unionId,
      villageId: villageId ?? this.villageId,
      villageName: villageName ?? this.villageName,
      areaLabel: areaLabel ?? this.areaLabel,
      line1: line1 ?? this.line1,
      postalCode: postalCode ?? this.postalCode,
    );
  }

  factory ProfileLocationDraft.fromAddress(MobileMeAddressDto? address) {
    if (address == null) return const ProfileLocationDraft();
    return ProfileLocationDraft(
      divisionId: address.divisionId,
      districtId: address.districtId,
      upazilaId: address.upazilaId,
      unionId: address.unionId,
      villageId: address.villageId,
      villageName: address.villageName,
      line1: address.line1,
      postalCode: address.postalCode,
    );
  }

  factory ProfileLocationDraft.fromJson(Map<String, dynamic> json) {
    return ProfileLocationDraft(
      divisionId: json['divisionId'] as String?,
      districtId: json['districtId'] as String?,
      upazilaId: json['upazilaId'] as String?,
      unionId: json['unionId'] as String?,
      villageId: json['villageId'] as String?,
      villageName: json['villageName'] as String?,
      areaLabel: json['areaLabel'] as String?,
      line1: json['line1'] as String?,
      postalCode: json['postalCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (divisionId != null) 'divisionId': divisionId,
    if (districtId != null) 'districtId': districtId,
    if (upazilaId != null) 'upazilaId': upazilaId,
    if (unionId != null) 'unionId': unionId,
    if (villageId != null) 'villageId': villageId,
    if (villageName != null) 'villageName': villageName,
    if (areaLabel != null) 'areaLabel': areaLabel,
    if (line1 != null) 'line1': line1,
    if (postalCode != null) 'postalCode': postalCode,
  };

  MobileMeAddressDto toAddressDto() {
    return MobileMeAddressDto(
      divisionId: divisionId,
      districtId: districtId,
      upazilaId: upazilaId,
      unionId: unionId,
      villageId: villageId,
      villageName: villageName,
      line1: line1,
      postalCode: postalCode,
    );
  }
}

class ProfileLocationDraftNotifier extends AsyncNotifier<ProfileLocationDraft> {
  LocalCacheService get _cache => ref.read(localCacheServiceProvider);

  @override
  Future<ProfileLocationDraft> build() async {
    final raw = await _cache.read(_locationDraftKey);
    if (raw != null) {
      return ProfileLocationDraft.fromJson(raw);
    }
    return const ProfileLocationDraft();
  }

  Future<void> hydrateFromProfile(MobileMeDto profile) async {
    final draft = ProfileLocationDraft.fromAddress(profile.address).copyWith(
      areaLabel: profile.area,
    );
    await _persist(draft);
    state = AsyncData(draft);
  }

  Future<void> saveDraft(ProfileLocationDraft draft) async {
    await _persist(draft);
    state = AsyncData(draft);
  }

  Future<void> _persist(ProfileLocationDraft draft) async {
    await _cache.write(
      _locationDraftKey,
      draft.toJson(),
      LocalCacheContract.profileTtl,
    );
  }
}

final profileLocationDraftProvider =
    AsyncNotifierProvider<ProfileLocationDraftNotifier, ProfileLocationDraft>(
      ProfileLocationDraftNotifier.new,
    );
