import 'area_dto.dart';

/// Bangladesh location hierarchy — mobile compat API (`/api/mobile/locations/*`).
abstract class AreaRepositoryContract {
  Future<AreaPage<AreaNodeDto>> getDivisions({
    int page = 1,
    int pageSize = 20,
    String locale = 'bn',
  });

  Future<AreaPage<AreaNodeDto>> getDistricts(
    String divisionId, {
    int page = 1,
    int pageSize = 20,
    String locale = 'bn',
  });

  Future<AreaPage<AreaNodeDto>> getUpazilas(
    String districtId, {
    int page = 1,
    int pageSize = 20,
    String locale = 'bn',
  });

  Future<AreaPage<AreaNodeDto>> getUnions({
    required String districtId,
    required String upazilaId,
    int page = 1,
    int pageSize = 20,
    String locale = 'bn',
  });

  Future<AreaPage<AreaNodeDto>> getVillages(
    String unionId, {
    int page = 1,
    int pageSize = 20,
    String locale = 'bn',
  });

  Future<AreaPage<AreaSearchHitDto>> search({
    required String query,
    String level = 'ALL',
    int limit = 25,
    String locale = 'bn',
    String? divisionId,
    String? districtId,
    String? upazilaId,
    String? unionId,
  });
}

/// HTTP path map for Dio implementations (backend: `legacy/web/routes/mobile/locations`).
abstract class AreaApiPaths {
  static const divisions = '/api/mobile/locations/divisions';
  static const districts = '/api/mobile/locations/districts';
  static const upazilas = '/api/mobile/locations/upazilas';
  static const unions = '/api/mobile/locations/unions';
  static const villages = '/api/mobile/locations/villages';
  static const search = '/api/mobile/locations/search';
}

/// Backend requires both parent IDs for union listing.
class AreaUnionQuery {
  const AreaUnionQuery({required this.districtId, required this.upazilaId});

  final String districtId;
  final String upazilaId;

  @override
  bool operator ==(Object other) {
    return other is AreaUnionQuery &&
        other.districtId == districtId &&
        other.upazilaId == upazilaId;
  }

  @override
  int get hashCode => Object.hash(districtId, upazilaId);
}
